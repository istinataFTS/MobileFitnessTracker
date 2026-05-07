import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import '../../../domain/repositories/voice_repository.dart';
import '../../../domain/usecases/voice/delete_voice_history.dart';
import '../../../domain/usecases/voice/get_voice_budget.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class VoiceSessionStarted extends VoiceEvent {
  const VoiceSessionStarted(this.session);

  final AppSession session;

  @override
  List<Object?> get props => <Object?>[session];
}

class VoiceTranscribeRequested extends VoiceEvent {
  const VoiceTranscribeRequested({
    required this.audioBytes,
    required this.mimeType,
  });

  final List<int> audioBytes;
  final String mimeType;

  @override
  List<Object?> get props => <Object?>[audioBytes, mimeType];
}

class VoiceSendMessage extends VoiceEvent {
  const VoiceSendMessage(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

class VoiceBudgetRefreshRequested extends VoiceEvent {}

class VoiceHistoryDeleteRequested extends VoiceEvent {}

class VoiceConversationCleared extends VoiceEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

enum VoiceStatus {
  idle,
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
    this.lastAudioBytes,
  });

  final VoiceStatus status;
  final List<VoiceMessage> messages;
  final VoiceBudget? budget;
  final String? sessionId;
  final bool isGuest;
  final String? errorMessage;
  final List<int>? lastAudioBytes;

  bool get isBusy =>
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
    List<int>? lastAudioBytes,
    bool clearError = false,
    bool clearAudio = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      budget: budget ?? this.budget,
      sessionId: sessionId ?? this.sessionId,
      isGuest: isGuest ?? this.isGuest,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastAudioBytes: clearAudio ? null : lastAudioBytes ?? this.lastAudioBytes,
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
        lastAudioBytes,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({
    required VoiceRepository repository,
    required GetVoiceBudget getVoiceBudget,
    required DeleteVoiceHistory deleteVoiceHistory,
  })  : _repository = repository,
        _getVoiceBudget = getVoiceBudget,
        _deleteVoiceHistory = deleteVoiceHistory,
        super(const VoiceState()) {
    on<VoiceSessionStarted>(_onSessionStarted);
    on<VoiceTranscribeRequested>(_onTranscribeRequested);
    on<VoiceSendMessage>(_onSendMessage);
    on<VoiceBudgetRefreshRequested>(_onBudgetRefresh);
    on<VoiceHistoryDeleteRequested>(_onHistoryDelete);
    on<VoiceConversationCleared>(_onConversationCleared);
  }

  static const int _maxHistoryTurns = 3;
  static const _uuid = Uuid();

  final VoiceRepository _repository;
  final GetVoiceBudget _getVoiceBudget;
  final DeleteVoiceHistory _deleteVoiceHistory;

  // ---------------------------------------------------------------------------

  void _onSessionStarted(VoiceSessionStarted event, Emitter<VoiceState> emit) {
    final isGuest = !event.session.isAuthenticated;
    final sessionId = isGuest ? null : _uuid.v4();
    emit(state.copyWith(
      isGuest: isGuest,
      sessionId: sessionId,
      messages: const <VoiceMessage>[],
      clearError: true,
    ));
  }

  // ---------------------------------------------------------------------------

  Future<void> _onTranscribeRequested(
    VoiceTranscribeRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (_isGuestOrBusy(emit)) return;
    final sid = _ensureSessionId(emit);

    emit(state.copyWith(status: VoiceStatus.transcribing, clearError: true));

    final result = await _repository.transcribe(
      audioBytes: event.audioBytes,
      sessionId: sid,
      mimeType: event.mimeType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: _messageFor(failure),
      )),
      (transcript) {
        if (transcript.isNotEmpty) {
          add(VoiceSendMessage(transcript));
        } else {
          emit(state.copyWith(status: VoiceStatus.idle));
        }
      },
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _onSendMessage(
    VoiceSendMessage event,
    Emitter<VoiceState> emit,
  ) async {
    if (_isGuestOrBusy(emit)) return;
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
    ));

    // We keep only the last N turns for context to cap token usage.
    final historyForApi = updatedMessages.length > _maxHistoryTurns
        ? updatedMessages.sublist(updatedMessages.length - _maxHistoryTurns)
        : updatedMessages;

    final chatResult = await _repository.chat(
      userMessage: event.text,
      sessionId: sid,
      history: historyForApi,
      settings: const VoiceSettings.defaults(),
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

        await _synthesiseAndEmit(assistantMsg.content, sid, emit, withReply);
      },
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _synthesiseAndEmit(
    String text,
    String sessionId,
    Emitter<VoiceState> emit,
    List<VoiceMessage> messages,
  ) async {
    final ttsResult = await _repository.synthesise(
      text: text,
      sessionId: sessionId,
      voice: TtsVoice.nova,
    );

    ttsResult.fold(
      (failure) => emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: _messageFor(failure),
        messages: messages,
      )),
      (audioBytes) {
        emit(state.copyWith(
          status: VoiceStatus.idle,
          messages: messages,
          lastAudioBytes: audioBytes,
        ));
        _refreshBudget();
      },
    );
  }

  void _refreshBudget() => add(VoiceBudgetRefreshRequested());

  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------

  void _onConversationCleared(
    VoiceConversationCleared event,
    Emitter<VoiceState> emit,
  ) {
    emit(state.copyWith(
      messages: const <VoiceMessage>[],
      sessionId: _uuid.v4(),
      clearError: true,
      clearAudio: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isGuestOrBusy(Emitter<VoiceState> emit) {
    if (state.isGuest) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Sign in to use the voice assistant.',
      ));
      return true;
    }
    if (state.isBusy) return true;
    return false;
  }

  String _ensureSessionId(Emitter<VoiceState> emit) {
    final sid = state.sessionId ?? _uuid.v4();
    if (state.sessionId == null) {
      emit(state.copyWith(sessionId: sid));
    }
    return sid;
  }

  String _messageFor(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    return failure.message.isNotEmpty ? failure.message : 'Something went wrong.';
  }
}
