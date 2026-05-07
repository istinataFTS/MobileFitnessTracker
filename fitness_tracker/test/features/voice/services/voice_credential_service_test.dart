import 'package:fitness_tracker/features/voice/data/services/secure_storage_voice_credential_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kPicovoiceKey = 'voice.picovoice_access_key';

SecureStorageVoiceCredentialService _makeService(
        FlutterSecureStorage storage) =>
    SecureStorageVoiceCredentialService(storage);

void main() {
  late MockFlutterSecureStorage storage;
  late SecureStorageVoiceCredentialService service;

  setUp(() {
    storage = MockFlutterSecureStorage();
    service = _makeService(storage);
  });

  group('SecureStorageVoiceCredentialService', () {
    test('getPicovoiceAccessKey reads from the correct storage key', () async {
      when(() => storage.read(key: _kPicovoiceKey))
          .thenAnswer((_) async => 'my-key');

      final result = await service.getPicovoiceAccessKey();
      expect(result, 'my-key');
      verify(() => storage.read(key: _kPicovoiceKey)).called(1);
    });

    test('getPicovoiceAccessKey returns null when key absent', () async {
      when(() => storage.read(key: _kPicovoiceKey))
          .thenAnswer((_) async => null);

      expect(await service.getPicovoiceAccessKey(), isNull);
    });

    test('setPicovoiceAccessKey writes trimmed key to storage', () async {
      when(() => storage.write(key: _kPicovoiceKey, value: 'trimmed-key'))
          .thenAnswer((_) async {});

      await service.setPicovoiceAccessKey('  trimmed-key  ');
      verify(() => storage.write(key: _kPicovoiceKey, value: 'trimmed-key'))
          .called(1);
    });

    test('setPicovoiceAccessKey throws ArgumentError on empty string', () {
      expect(
        () => service.setPicovoiceAccessKey(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setPicovoiceAccessKey throws ArgumentError on whitespace-only string',
        () {
      expect(
        () => service.setPicovoiceAccessKey('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('clearPicovoiceAccessKey deletes the correct storage key', () async {
      when(() => storage.delete(key: _kPicovoiceKey))
          .thenAnswer((_) async {});

      await service.clearPicovoiceAccessKey();
      verify(() => storage.delete(key: _kPicovoiceKey)).called(1);
    });

    test('hasPicovoiceAccessKey returns false when storage is empty', () async {
      when(() => storage.read(key: _kPicovoiceKey))
          .thenAnswer((_) async => null);

      expect(await service.hasPicovoiceAccessKey(), isFalse);
    });

    test('hasPicovoiceAccessKey returns true after a key is set', () async {
      when(() => storage.read(key: _kPicovoiceKey))
          .thenAnswer((_) async => 'some-key');

      expect(await service.hasPicovoiceAccessKey(), isTrue);
    });

    test('hasPicovoiceAccessKey returns false for empty string in storage',
        () async {
      when(() => storage.read(key: _kPicovoiceKey))
          .thenAnswer((_) async => '');

      expect(await service.hasPicovoiceAccessKey(), isFalse);
    });
  });
}
