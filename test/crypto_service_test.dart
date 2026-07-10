import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/firebase/crypto_service.dart';

void main() {
  final crypto = CryptoService.instance;

  test('encrypt/decrypt round-trip with DEK', () async {
    final dek = await crypto.generateDek();
    final data = {
      'accounts': [
        {'name': 'BCA', 'balance': 1500000}
      ],
      'themeMode': 'dark',
    };
    final payload = await crypto.encrypt(data, dek);
    expect(payload.ciphertext, isNotEmpty);

    final restored = await crypto.decrypt(payload, dek);
    expect(restored, data);
  });

  test('wrong DEK fails to decrypt (MAC mismatch)', () async {
    final dekA = await crypto.generateDek();
    final dekB = await crypto.generateDek();
    final payload = await crypto.encrypt({'x': 1}, dekA);

    expect(
      () => crypto.decrypt(payload, dekB),
      throwsA(isA<WrongKeyException>()),
    );
  });

  test('wrap/unwrap DEK with password round-trip', () async {
    final dek = await crypto.generateDek();
    const password = 'rahasia123';
    final blob = await crypto.wrapDek(dek, password);

    final unwrapped = await crypto.unwrapDek(blob, password);
    final dekBytes = await dek.extractBytes();
    final unwrappedBytes = await unwrapped.extractBytes();
    expect(unwrappedBytes, dekBytes);
  });

  test('unwrap DEK with wrong password fails', () async {
    final dek = await crypto.generateDek();
    final blob = await crypto.wrapDek(dek, 'password-benar');

    expect(
      () => crypto.unwrapDek(blob, 'password-salah'),
      throwsA(isA<WrongKeyException>()),
    );
  });

  test('recovery key can unwrap a DEK wrapped with it', () async {
    final dek = await crypto.generateDek();
    final recovery = await crypto.generateRecoveryKey();
    // Pembungkusan & pembukaan memakai bentuk ternormalisasi yang sama,
    // sehingga pemisah/beda kapital saat input tidak jadi masalah.
    final blob =
        await crypto.wrapDek(dek, CryptoService.normalizeRecoveryKey(recovery));

    final unwrapped = await crypto.unwrapDek(
      blob,
      CryptoService.normalizeRecoveryKey(recovery),
    );
    final dekBytes = await dek.extractBytes();
    final unwrappedBytes = await unwrapped.extractBytes();
    expect(unwrappedBytes, dekBytes);
  });

  test('recovery key works despite separator/case differences in input', () async {
    final dek = await crypto.generateDek();
    final recovery = await crypto.generateRecoveryKey();
    final blob =
        await crypto.wrapDek(dek, CryptoService.normalizeRecoveryKey(recovery));
    // Input pengguna yang acak-acak formatnya masih membuka kunci.
    final messy = recovery.toLowerCase().replaceAll('-', ' ');
    final unwrapped = await crypto.unwrapDek(
      blob,
      CryptoService.normalizeRecoveryKey(messy),
    );
    final dekBytes = await dek.extractBytes();
    final unwrappedBytes = await unwrapped.extractBytes();
    expect(unwrappedBytes, dekBytes);
  });

  test('recovery key normalization ignores separators & case', () async {
    expect(
      CryptoService.normalizeRecoveryKey('abcd-efgh ijkl'),
      'ABCDEFGHIJKL',
    );
  });
}
