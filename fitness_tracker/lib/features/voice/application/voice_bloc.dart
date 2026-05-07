import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/voice_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import '../../../domain/repositories/app_settings_repository.dart';
import '../../../domain/usecases/voice/delete_voice_history.dart';
import '../../../domain/usecases/voice/get_voice_budget.dart';
import '../../../domain/usecases/voice/send_voice_message.dart';
import '../../../domain/usecases/voice/synthesise_speech.dart';
import '../../../domain/usecases/voice/transcribe_audio.dart';
import '../data/services/voice_credential_service.dart';
import '../data/services/voice_permission_service.dart';

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

class VoicePermissionOpenSettingsRequested extends VoiceEvent {
  const VoicePermissionOpenSettingsRequested();
}

class VoicePicovoiceKeySet extends VoiceEvent {
  const VoicePicovoiceKeySet(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

class VoicePicovoiceKeyCleared extends VoiceEvent {
  const VoicePicovoiceKeyCleared();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum VoiceStatus {
  idle,
  transcribing,
  thinking,
  speaking,
  error,
  permissionDenied,
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
    this.permissionStatus,
    this.hasPicovoiceKey = false,
  });

  final VoiceStatus status;
  final List<VoiceMessage> messages;
  final VoiceBudget? budget;
  final String? sessionId;
  final bool isGuest;
  final String? errorMessage;
  final List<int>? lastAudioBytes;

  /// Current mic permission status. Null means not yet checked.
  final VoicePermissionStatus? permissionStatus;

  /// Whether a non-empty Picovoice access key is stored in secure storage.
  final bool hasPicovoiceKey;

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
    VoicePermissionStatus? permissionStatus,
    bool? hasPicovoiceKey,
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
      permissionStatus: permissionStatus ?? this.permissionStatus,
      hasPicovoiceKey: hasPicovoiceKey ?? this.hasPicovoiceKey,
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
        permissionStatus,
        hasPicovoiceKey,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({
    required TranscribeAudio transcribeAudio,
    required SendVoiceMessage sendVoiceMessage,
    required SynthesizeSpeech synthesizeSpeech,
    required GetVoiceBudget getVoiceBudget,
    required DeleteVoiceHistory deleteVoiceHistory,
    required VoicePermissionService permissionService,
    required VoiceCredentialService credentialService,
    required AppSettingsRepository appSettingsRepository,
  })  : _transcribeAudio = transcribeAudio,
        _sendVoiceMessage = sendVoiceMessage,
        _synthesizeSpeech = synthesizeSpeech,
        _getVoiceBudget = getVoiceBudget,
        _deleteVoiceHistory = deleteVoiceHistory,
        _permissionService = permissionService,
        _credentialService = credentialService,
        _appSettingsRepository = appSettingsRepository,
        super(const VoiceState()) {
    on<VoiceSessionStarted>(_onSessionStarted);
    on<VoiceTranscribeRequested>(_onTranscribeRequested);
    on<VoiceSendMessage>(_onSendMessage);
    on<VoiceBudgetRefreshRequested>(_onBudgetRefresh);
    on<VoiceHistoryDeleteRequested>(_onHistoryDelete);
    on<VoiceConversationCleared>(_onConversationCleared);
    on<VoicePermissionOpenSettingsRequested>(_onPermissionOpenSettings);
    on<VoicePicovoiceKeySet>(_onPicovoiceKeySet);
    on<VoicePicovoiceKeyCleared>(_onPicovoiceKeyCleared);
  }

  static const _uuid = Uuid();

  final TranscribeAudio _transcribeAudio;
  final SendVoiceMessage _sendVoiceMessage;
  final SynthesizeSpeech _synthesizeSpeech;
  final GetVoiceBudget _getVoiceBudget;
  final DeleteVoiceHistory _deleteVoiceHistory;
  final VoicePermissionService _permissionService;
  final VoiceCredentialService _credentialService;
  final AppSettingsRepository _appSettingsRepository;

  // ---------------------------------------------------------------------------
  // Session start — auth gate → permission gate → credential check
  // ---------------------------------------------------------------------------

  Future<void> _onSessionStarted(
    VoiceSessionStarted event,
    Emitter<VoiceState> emit,
  ) async {
    final isGuest = !event.session.isAuthenticated;
    if (isGuest) {
      emit(state.copyWith(
        isGuest: true,
        sessionId: null,
        messages: const <VoiceMessage>[],
        clearError: true,
      ));
      return;
    }

    // 1. Check existing permission (no dialog).
    var permStatus = await _permissionService.checkMicrophonePermission();

    // 2. If not yet granted, request (shows system dialog on first call).
    if (permStatus != VoicePermissionStatus.granted) {
      permStatus = await _permissionService.requestMicrophonePermission();
    }

    // 3. If still not granted, surface the error and stop.
    if (permStatus != VoicePermissionStatus.granted) {
      final message = permStatus == VoicePermissionStatus.deniedPermanently
          ? AppStrings.voicePermissionDeniedPermanently
          : AppStrings.voicePermissionDenied;
      emit(state.copyWith(
        isGuest: false,
        status: VoiceStatus.permissionDenied,
        permissionStatus: permStatus,
        errorMessage: message,
        messages: const <VoiceMessage>[],
      ));
      return;
    }

    // 4. Permission granted — emit updated status and check Picovoice key.
    final hasKey = await _credentialService.hasPicovoiceAccessKey();
    final sessionId = _uuid.v4();

    emit(state.copyWith(
      isGuest: false,
      status: VoiceStatus.idle,
      sessionId: sessionId,
      messages: const <VoiceMessage>[],
      permissionStatus: VoicePermissionStatus.granted,
      hasPicovoiceKey: hasKey,
      clearError: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Transcribe
  // ---------------------------------------------------------------------------

  Future<void> _onTranscribeRequested(
    VoiceTranscribeRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (_isGuestOrBusy(emit)) return;
    final sid = _ensureSessionId(emit);

    final settings = await _currentVoiceSettings();

    emit(state.copyWith(status: VoiceStatus.transcribing, clearError: true));

    final result = await _transcribeAudio(
      audioBytes: event.audioBytes,
      sessionId: sid,
      mimeType: event.mimeType,
      sessionLoggingEnabled: settings.sessionLoggingEnabled,
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
  // Chat
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

    final settingsResult = await _appSettingsRepository.getSettings();
    final weightUnit = settingsResult.fold(
      (_) => WeightUnit.kilograms,
      (s) => s.weightUnit,
    );
    final voiceSettings = settingsResult.fold(
      (_) => const VoiceSettings.defaults(),
      (s) => s.voiceSettings,
    );

    // Cap history at the last N turns before sending to the API.
    final historyForApi = _trimmedHistory(updatedMessages);

    final chatResult = await _sendVoiceMessage(
      userMessage: event.text,
      sessionId: sid,
      history: historyForApi,
      settings: voiceSettings,
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

        await _synthesiseAndEmit(
          assistantMsg.content,
          sid,
          voiceSettings.ttsVoice,
          voiceSettings.sessionLoggingEnabled,
          emit,
          withReply,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Budget
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
  // History delete
  // ---------------------------------------------------------------------------

  Future<void> _onHistoryDelete(
    VoiceHistoryDeleteRequested event,
    Emitter<VoiceState> emit,
  ) async {
    if (state.isGuest) return;
    final result = await _deleteVoiceHistory();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: _messageFor(failure))),
      (_) => emit(state.copyWith(
        messages: const <VoiceMessage>[],
        sessionId: _uuid.v4(),
        clearError: true,
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Conversation clear
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
  // Permission: open settings
  // ---------------------------------------------------------------------------

  Future<void> _onPermissionOpenSettings(
    VoicePermissionOpenSettingsRequested event,
    Emitter<VoiceState> emit,
  ) async {
    await _permissionService.openAppSettings();
  }

  // ---------------------------------------------------------------------------
  // Picovoice key management
  // ---------------------------------------------------------------------------

  Future<void> _onPicovoiceKeySet(
    VoicePicovoiceKeySet event,
    Emitter<VoiceState> emit,
  ) async {
    try {
      await _credentialService.setPicovoiceAccessKey(event.key);
      emit(state.copyWith(hasPicovoiceKey: true));
    } catch (e) {
      AppLogger.warning(
        'VoiceBloc: failed to store Picovoice key',
        category: 'voice',
        error: e,
      );
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: AppStrings.voicePicovoiceKeyMissing,
      ));
    }
  }

  Future<void> _onPicovoiceKeyCleared(
    VoicePicovoiceKeyCleared event,
    Emitter<VoiceState> emit,
  ) async {
    await _credentialService.clearPicovoiceAccessKey();
    emit(state.copyWith(hasPicovoiceKey: false));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _synthesiseAndEmit(
    String text,
    String sessionId,
    TtsVoice voice,
    bool sessionLoggingEnabled,
    Emitter<VoiceState> emit,
    List<VoiceMessage> messages,
  ) async {
    final ttsResult = await _synthesizeSpeech(
      text: text,
      sessionId: sessionId,
      voice: voice,
      sessionLoggingEnabled: sessionLoggingEnabled,
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

  Future<VoiceSettings> _currentVoiceSettings() async {
    final result = await _appSettingsRepository.getSettings();
    return result.fold(
      (_) => const VoiceSettings.defaults(),
      (s) => s.voiceSettings,
    );
  }

  List<VoiceMessage> _trimmedHistory(List<VoiceMessage> messages) {
    return messages.length > VoiceConstants.maxHistoryTurns
        ? messages.sublist(messages.length - VoiceConstants.maxHistoryTurns)
        : messages;
  }

  bool _isGuestOrBusy(Emitter<VoiceState> emit) {
    if (state.isGuest) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: AppStrings.voiceErrorGuestForbidden,
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
    return failure.message.isNotEmpty
        ? failure.message
        : AppStrings.voiceErrorGeneric;
  }
}
