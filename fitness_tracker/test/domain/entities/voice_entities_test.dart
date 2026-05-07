import 'package:fitness_tracker/domain/entities/voice_budget.dart';
import 'package:fitness_tracker/domain/entities/voice_message.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceBudget', () {
    test('remainingUsd is capped at 0 when overspent', () {
      const budget = VoiceBudget(usedUsd: 1.5, dailyCapUsd: 1.0);
      expect(budget.remainingUsd, 0.0);
    });

    test('usedFraction returns correct ratio', () {
      const budget = VoiceBudget(usedUsd: 0.5, dailyCapUsd: 1.0);
      expect(budget.usedFraction, 0.5);
    });

    test('isExhausted is true when remainingUsd is 0', () {
      const budget = VoiceBudget(usedUsd: 1.0, dailyCapUsd: 1.0);
      expect(budget.isExhausted, isTrue);
    });

    test('isExhausted is false when budget has remaining amount', () {
      const budget = VoiceBudget(usedUsd: 0.3, dailyCapUsd: 1.0);
      expect(budget.isExhausted, isFalse);
    });

    test('usedFraction is 0 when dailyCapUsd is 0', () {
      const budget = VoiceBudget(usedUsd: 0.0, dailyCapUsd: 0.0);
      expect(budget.usedFraction, 0.0);
    });

    test('equality holds for same values', () {
      const a = VoiceBudget(usedUsd: 0.2, dailyCapUsd: 1.0);
      const b = VoiceBudget(usedUsd: 0.2, dailyCapUsd: 1.0);
      expect(a, b);
    });
  });

  group('VoiceMessage', () {
    test('user message has correct role', () {
      final msg = VoiceMessage(
        role: VoiceRole.user,
        content: 'bench press',
        createdAt: DateTime(2026),
      );
      expect(msg.role, VoiceRole.user);
      expect(msg.content, 'bench press');
    });

    test('assistant message has correct role', () {
      final msg = VoiceMessage(
        role: VoiceRole.assistant,
        content: 'Got it!',
        createdAt: DateTime(2026),
      );
      expect(msg.role, VoiceRole.assistant);
    });

    test('equality holds for same values', () {
      final t = DateTime(2026);
      final a = VoiceMessage(role: VoiceRole.user, content: 'hi', createdAt: t);
      final b = VoiceMessage(role: VoiceRole.user, content: 'hi', createdAt: t);
      expect(a, b);
    });
  });

  group('VoiceSettings', () {
    test('defaults are off / nova', () {
      const s = VoiceSettings.defaults();
      expect(s.sessionLoggingEnabled, isFalse);
      expect(s.ttsVoice, TtsVoice.nova);
    });

    test('copyWith overrides only specified fields', () {
      const original = VoiceSettings.defaults();
      final updated = original.copyWith(ttsVoice: TtsVoice.echo);
      expect(updated.ttsVoice, TtsVoice.echo);
      expect(updated.sessionLoggingEnabled, isFalse);
    });

    test('TtsVoice.nova has correct apiValue', () {
      expect(TtsVoice.nova.apiValue, 'nova');
    });

    test('TtsVoice.alloy has correct displayName', () {
      expect(TtsVoice.alloy.displayName, 'Alloy');
    });
  });
}
