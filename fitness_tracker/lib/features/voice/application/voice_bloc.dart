import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/voice_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/entities/app_settings.dart' show WeightUnit;
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import '../../../domain/entities/voice_tool_call.dart';
import '../../../domain/repositories/app_settings_repository.dart';
import '../../../domain/usecases/voice/delete_voice_history.dart';
import '../../../domain/usecases/voice/get_voice_budget.dart';
import '../../../domain/usecases/voice/send_voice_message.dart';
import '../data/services/voice_stt_service.dart';
import '../data/services/voice_tts_service.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Fired when a voice session begins (user opens the overlay or wakes
/// the bot). Carries the current auth session so guests can be
/// rejected before any network call.
class VoiceSessionStarted extends VoiceEvent {
  const VoiceSessionStarted(this.session);

  final AppSession session;

  @override
  List<Object?> get props => <Object?>[session];
}

/// Starts an STT session. Pure event — the bloc subscribes to the
/// stream emitted by the [VoiceSttService] and forwards the final
/// transcript as a [VoiceSendMessage].
class VoiceListenRequested extends VoiceEvent {
  const VoiceListenRequested();
}

/// Stops an in-progress STT session gracefully (the final partial
/// becomes the final transcript).
class VoiceListenStopRequested extends VoiceEvent {
  const VoiceListenStopRequested();
}

/// Internal: emitted by the bloc itself when STT yields a result.
/// Public so widget tests can drive the bloc directly without
/// plumbing a real STT engine.
class VoiceTranscriptReceived extends VoiceEvent {
  const VoiceTranscriptReceived({
    required this.transcript,
    required this.isFinal,
  });

  final String transcript;
  final bool isFinal;

  @override
  List<Object?> get props => <Object?>[transcript, isFinal];
}

/// Internal: emitted by the bloc when STT errors out.
class VoiceTranscriptFailed extends VoiceEvent {
  const VoiceTranscriptFailed(this.kind, [this.message]);

  final VoiceSttErrorKind kind;
  final String? message;

  @override
  List<Object?> get props => <Object?>[kind, message];
}

class VoiceSendMessage extends VoiceEvent {
  const VoiceSendMessage(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

class VoiceBudgetRefreshRequested extends VoiceEvent {
  const VoiceBudgetRefreshRequested();
}

class VoiceHistoryDeleteRequested extends VoiceEvent {
  const VoiceHistoryDeleteRequested();
}

class VoiceConversationCleared extends VoiceEvent {
  const VoiceConversationCleared();
}

// ---------------------------------------------------------------------------
// C-3 events — confirmation card & workout mode
// ---------------------------------------------------------------------------

/// C-5 fires this after parsing a tool call from the LLM response.
/// Passing [null] clears an in-progress confirmation card.
class VoicePendingConfirmationSet extends VoiceEvent {
  const VoicePendingConfirmationSet(this.toolCall);

  final VoiceToolCall? toolCall;

  @override
  List<Object?> get props => <Object?>[toolCall];
}

/// User tapped "Yes, do it" on the confirmation card.
/// C-5 replaces the stub handler with real bloc dispatch.
class VoiceConfirmationAccepted extends VoiceEvent {
  const VoiceConfirmationAccepted();
}

/// User tapped "Cancel" on the confirmation card.
class VoiceConfirmationCancelled extends VoiceEvent {
  const VoiceConfirmationCancelled();
}

/// User toggled Workout Mode inside the overlay.
/// The wakelock itself is applied in C-4; this event updates UI state.
class VoiceWorkoutModeToggled extends VoiceEvent {
  const VoiceWorkoutModeToggled({required this.active});

  final bool active;

  @override
  List<Object?> get props => <Object?>[active];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum VoiceStatus {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
}

class VoiceState extends Equatable {
  const VoiceState({
    this.status = VoiceStatus.idle,
    this.messages = const <VoiceMessage>[],
    this.budget,
    this.sessionId,
    this.isGuest = false,
    this.errorMessage,
    this.liveTranscript = '',
    this.pendingConfirmation,
    this.isWorkoutModeActive = false,
  });

  /// Top-level state machine. Maps directly to overlay states in C-3.
  final VoiceStatus status;

  /// Conversation so far this session (user + assistant turns).
  final List<VoiceMessage> messages;

  /// Latest known budget snapshot — drives the budget meter.
  final VoiceBudget? budget;

  /// Server-side session UUID. Null until [VoiceSessionStarted] fires.
  final String? sessionId;

  /// True for unauthenticated sessions — voice features are gated
  /// behind sign-in in v1.
  final bool isGuest;

  /// Set when [status] == [VoiceStatus.error]. Already mapped to a
  /// user-facing string by the bloc; the UI never has to translate.
  final String? errorMessage;

  /// Partial transcript displayed live in the overlay while STT is
  /// running. Cleared on transition to [VoiceStatus.thinking].
  final String liveTranscript;

  /// Non-null when the LLM returned a tool call awaiting confirmation.
  /// C-3 renders [VoiceConfirmationCard] while this is set.
  /// C-5 populates it via [VoicePendingConfirmationSet]; until then
  /// it remains null and the card is hidden.
  final VoiceToolCall? pendingConfirmation;

  /// True when the user has activated Workout Mode in the overlay.
  /// The actual wakelock is applied in C-4; this flag drives the banner
  /// and the toggle switch in [VoiceOverlayStatusView].
  final bool isWorkoutModeActive;

  bool get isBusy =>
      status == VoiceStatus.listening ||
      status == VoiceStatus.transcribing ||
      status == VoiceStatus.thinking ||
      status == VoiceStatus.speaking;

  VoiceState copyWith({
    VoiceStatus? status,
    List<VoiceMessage>? messages,
    VoiceBudget? budget,
    String? sessionId,
    bool? isGuest,
    String? errorMessage,
    String? liveTranscript,
    VoiceToolCall? pendingConfirmation,
    bool? isWorkoutModeActive,
    bool clearError = false,
    bool clearTranscript = false,
    bool clearPendingConfirmation = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      budget: budget ?? this.budget,
      sessionId: sessionId ?? this.sessionId,
      isGuest: isGuest ?? this.isGuest,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      liveTranscript:
          clearTranscript ? '' : liveTranscript ?? this.liveTranscript,
      pendingConfirmation: clearPendingConfirmation
          ? null
          : pendingConfirmation ?? this.pendingConfirmation,
      isWorkoutModeActive: isWorkoutModeActive ?? this.isWorkoutModeActive,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        messages,
        budget,
        sessionId,
        isGuest,
        errorMessage,
        liveTranscript,
        pendingConfirmation,
        isWorkoutModeActive,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

/// Voice-bot state machine.
///
/// **Critical architectural rule:** this bloc does NOT depend on
/// `VoiceRepository` directly. All data access goes through use
/// cases ([SendVoiceMessage], [GetVoiceBudget], [DeleteVoiceHistory])
/// and through device service ports ([VoiceSttService],
/// [VoiceTtsService]). This keeps the bloc testable with simple
/// fakes and ensures the data layer can swap implementations
/// without touching application code.
class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({
    required SendVoiceMessage sendVoiceMessage,
    required GetVoiceBudget getVoiceBudget,
    required DeleteVoiceHistory deleteVoiceHistory,
    required VoiceSttService sttService,
    required VoiceTtsService ttsService,
    required AppSettingsRepository appSettingsRepository,
    required VoiceSettings Function() currentVoiceSettings,
  })  : _sendVoiceMessage = sendVoiceMessage,
        _getVoiceBudget = getVoiceBudget,
        _deleteVoiceHistory = deleteVoiceHistory,
        _stt = sttService,
        _tts = ttsService,
        _appSettingsRepository = appSettingsRepository,
        _currentVoiceSettings = currentVoiceSettings,
        super(const VoiceState()) {
    on<VoiceSessionStarted>(_onSessionStarted);
    on<VoiceListenRequested>(_onListenRequested);
    on<VoiceListenStopRequested>(_onListenStopRequested);
    on<VoiceTranscriptReceived>(_onTranscriptReceived);
    on<VoiceTranscriptFailed>(_onTranscriptFailed);
    on<VoiceSendMessage>(_onSendMessage);
    on<VoiceBudgetRefreshRequested>(_onBudgetRefresh);
    on<VoiceHistoryDeleteRequested>(_onHistoryDelete);
    on<VoiceConversationCleared>(_onConversationCleared);
    // C-3 events
    on<VoicePendingConfirmationSet>(_onPendingConfirmationSet);
    on<VoiceConfirmationAccepted>(_onConfirmationAccepted);
    on<VoiceConfirmationCancelled>(_onConfirmationCancelled);
    on<VoiceWorkoutModeToggled>(_onWorkoutModeToggled);
  }

  static const _uuid = Uuid();

  final SendVoiceMessage _sendVoiceMessage;
  final GetVoiceBudget _getVoiceBudget;
  final DeleteVoiceHistory _deleteVoiceHistory;
  final VoiceSttService _stt;
  final VoiceTtsService _tts;
  final AppSettingsRepository _appSettingsRepository;

  /// Injected as a callback so the bloc reads the *current* settings
  /// at each request, never a stale snapshot captured at construction.
  /// In production this is `() => voiceSettingsCubit.state`.
  final VoiceSettings Function() _currentVoiceSettings;

  StreamSubscription<VoiceSttResult>? _sttSubscription;

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  void _onSessionStarted(VoiceSessionStarted event, Emitter<VoiceState> emit) {
    final isGuest = !event.session.isAuthenticated;
    final sessionId = isGuest ? null : _uuid.v4();
    emit(state.copyWith(
      isGuest: isGuest,
      sessionId: sessionId,
      messages: const <VoiceMessage>[],
      status: VoiceStatus.idle,
      clearError: true,
      clearTranscript: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // STT (device-native)
  // ---------------------------------------------------------------------------

  Future<void> _onListenRequested(
    VoiceListenRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (_rejectGuest(emit) || _rejectBusy()) return;
    _ensureSessionId(emit);

    try {
      await _stt.initialize();
    } catch (e, st) {
      AppLogger.warning('VoiceBloc: STT initialize failed',
          error: e, stackTrace: st);
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Voice recognition is not available on this device.',
      ));
      return;
    }

    if (!_stt.isAvailable) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Voice recognition is not available on this device.',
      ));
      return;
    }

    emit(state.copyWith(
      status: VoiceStatus.listening,
      clearError: true,
      clearTranscript: true,
    ));

    await _sttSubscription?.cancel();
    _sttSubscription = _stt.listen().listen(
      (result) => add(VoiceTranscriptReceived(
        transcript: result.transcript,
        isFinal: result.isFinal,
      )),
      onError: (Object e) {
        if (e is VoiceSttException) {
          add(VoiceTranscriptFailed(e.kind, e.message));
        } else {
          add(VoiceTranscriptFailed(VoiceSttErrorKind.unknown, e.toString()));
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _onListenStopRequested(
    VoiceListenStopRequested event,
    Emitter<VoiceState> emit,
  ) async {
    await _stt.stop();
  }

  void _onTranscriptReceived(
    VoiceTranscriptReceived event,
    Emitter<VoiceState> emit,
  ) {
    // Partial result — show live in the overlay but don't transition state.
    if (!event.isFinal) {
      emit(state.copyWith(liveTranscript: event.transcript));
      return;
    }

    // Final result. Cancel the subscription defensively in case the
    // platform plugin keeps the stream open for a heartbeat after the
    // final result.
    _sttSubscription?.cancel();
    _sttSubscription = null;

    final text = event.transcript.trim();
    if (text.isEmpty) {
      // "Didn't catch that" — drop back to idle without an error.
      // The C-4 layer can play "Repeat please" through TTS.
      emit(state.copyWith(
        status: VoiceStatus.idle,
        clearTranscript: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: VoiceStatus.transcribing,
      liveTranscript: text,
    ));
    add(VoiceSendMessage(text));
  }

  void _onTranscriptFailed(
    VoiceTranscriptFailed event,
    Emitter<VoiceState> emit,
  ) {
    _sttSubscription?.cancel();
    _sttSubscription = null;
    emit(state.copyWith(
      status: VoiceStatus.error,
      errorMessage: _sttErrorMessage(event.kind),
      clearTranscript: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  Future<void> _onSendMessage(
    VoiceSendMessage event,
    Emitter<VoiceState> emit,
  ) async {
    if (_rejectGuest(emit)) return;
    final sid = _ensureSessionId(emit);

    final userMsg = VoiceMessage(
      role: VoiceRole.user,
      content: event.text,
      createdAt: DateTime.now(),
    );

    final updatedMessages = <VoiceMessage>[...state.messages, userMsg];
    emit(state.copyWith(
      status: VoiceStatus.thinking,
      messages: updatedMessages,
      clearError: true,
      clearTranscript: true,
    ));

    final weightUnit = await _readWeightUnit();

    final history = _trimHistory(updatedMessages);
    final chatResult = await _sendVoiceMessage(
      userMessage: event.text,
      sessionId: sid,
      history: history,
      settings: _currentVoiceSettings(),
      weightUnit: weightUnit,
    );

    await chatResult.fold(
      (failure) async => emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: _messageFor(failure),
      )),
      (assistantMsg) async {
        final withReply = <VoiceMessage>[...updatedMessages, assistantMsg];
        emit(state.copyWith(
          status: VoiceStatus.speaking,
          messages: withReply,
        ));

        await _speak(assistantMsg.content);

        emit(state.copyWith(
          status: VoiceStatus.idle,
          messages: withReply,
        ));
        _refreshBudget();
      },
    );
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final settings = _currentVoiceSettings();
    // Apply current volume/rate before each speak so settings changes
    // mid-session are honored without restarting the TTS engine.
    await _tts.setVolume(settings.ttsVolume);
    await _tts.setSpeechRate(settings.ttsSpeechRate);
    await _tts.speak(text);
  }

  /// Trims `messages` to the last [VoiceConstants.maxHistoryTurns]
  /// entries. Bounded server-side too, but trimming on the client
  /// avoids sending oversize payloads.
  List<VoiceMessage> _trimHistory(List<VoiceMessage> messages) {
    if (messages.length <= VoiceConstants.maxHistoryTurns) return messages;
    return messages.sublist(messages.length - VoiceConstants.maxHistoryTurns);
  }

  Future<WeightUnit> _readWeightUnit() async {
    final result = await _appSettingsRepository.getSettings();
    return result.fold(
      // If settings can't be read, fall back to the safest default
      // (kg) rather than failing the chat call — the bot will still
      // function, just confirm in metric.
      (_) => WeightUnit.kilograms,
      (settings) => settings.weightUnit,
    );
  }

  // ---------------------------------------------------------------------------
  // Budget / history
  // ---------------------------------------------------------------------------

  void _refreshBudget() => add(const VoiceBudgetRefreshRequested());

  Future<void> _onBudgetRefresh(
    VoiceBudgetRefreshRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (state.isGuest) return;
    final result = await _getVoiceBudget();
    result.fold(
      (_) {},
      (budget) => emit(state.copyWith(budget: budget)),
    );
  }

  Future<void> _onHistoryDelete(
    VoiceHistoryDeleteRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (state.isGuest) return;
    final result = await _deleteVoiceHistory();
    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: _messageFor(failure),
      )),
      (_) => emit(state.copyWith(
        messages: const <VoiceMessage>[],
        sessionId: _uuid.v4(),
        clearError: true,
      )),
    );
  }

  void _onConversationCleared(
    VoiceConversationCleared event,
    Emitter<VoiceState> emit,
  ) {
    emit(state.copyWith(
      messages: const <VoiceMessage>[],
      sessionId: _uuid.v4(),
      status: VoiceStatus.idle,
      clearError: true,
      clearTranscript: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _rejectGuest(Emitter<VoiceState> emit) {
    if (!state.isGuest) return false;
    emit(state.copyWith(
      status: VoiceStatus.error,
      errorMessage: 'Sign in to use the voice assistant.',
    ));
    return true;
  }

  /// Returns true if the bloc is already mid-operation. Caller should
  /// silently drop the event — re-entering a state would corrupt the
  /// state machine.
  bool _rejectBusy() => state.isBusy;

  String _ensureSessionId(Emitter<VoiceState> emit) {
    final sid = state.sessionId ?? _uuid.v4();
    if (state.sessionId == null) {
      emit(state.copyWith(sessionId: sid));
    }
    return sid;
  }

  String _messageFor(Failure failure) {
    if (failure.message.isNotEmpty) return failure.message;
    return 'Something went wrong.';
  }

  /// Maps STT error kinds to user-visible strings. The bloc owns this
  /// mapping (rather than each widget) so the message is consistent
  /// wherever the error state is shown — overlay, settings, debug
  /// panel.
  String _sttErrorMessage(VoiceSttErrorKind kind) {
    switch (kind) {
      case VoiceSttErrorKind.permissionDenied:
        return 'Microphone access is required. Please allow it and try again.';
      case VoiceSttErrorKind.permissionPermanentlyDenied:
        return 'Microphone access is permanently denied. Enable it in system settings.';
      case VoiceSttErrorKind.unavailable:
        return 'Voice recognition is not available on this device.';
      case VoiceSttErrorKind.noSpeech:
        return 'I did not catch that. Please try again.';
      case VoiceSttErrorKind.network:
        return 'Voice recognition needs an internet connection right now.';
      case VoiceSttErrorKind.unknown:
        return 'Voice recognition failed. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // C-3 handlers — confirmation & workout mode
  // ---------------------------------------------------------------------------

  void _onPendingConfirmationSet(
    VoicePendingConfirmationSet event,
    Emitter<VoiceState> emit,
  ) {
    emit(state.copyWith(
      pendingConfirmation: event.toolCall,
      clearPendingConfirmation: event.toolCall == null,
    ));
  }

  void _onConfirmationAccepted(
    VoiceConfirmationAccepted event,
    Emitter<VoiceState> emit,
  ) {
    // C-5 replaces this stub with real tool dispatch to the appropriate
    // bloc (WorkoutLogBloc, NutritionLogBloc, etc.). Until then, simply
    // clear the card so the overlay returns to idle.
    emit(state.copyWith(clearPendingConfirmation: true));
  }

  void _onConfirmationCancelled(
    VoiceConfirmationCancelled event,
    Emitter<VoiceState> emit,
  ) {
    emit(state.copyWith(clearPendingConfirmation: true));
  }

  void _onWorkoutModeToggled(
    VoiceWorkoutModeToggled event,
    Emitter<VoiceState> emit,
  ) {
    // C-4 wires the wakelock call here. For now update the UI flag only.
    emit(state.copyWith(isWorkoutModeActive: event.active));
  }

  @override
  Future<void> close() async {
    await _sttSubscription?.cancel();
    _sttSubscription = null;
    await _tts.stop();
    await super.close();
  }
}
