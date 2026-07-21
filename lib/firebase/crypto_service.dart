import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Enkripsi sisi-klien (end-to-end) untuk data keuangan.
///
/// Skema: **envelope encryption**.
///   - Satu Data Key (DEK) acak 256-bit mengenkripsi seluruh [AppState]
///     (AES-GCM). DEK ini hanya ada di memori setelah dibuka.
///   - DEK dibungkus (dienkripsi) dua kali: oleh KEK turunan **password**
///     dan oleh KEK turunan **recovery key**. Keduanya PBKDF2-HMAC-SHA256.
///   - Hanya blob kunci (wrapped DEK + salt + nonce) yang tersimpan di server.
///     Tanpa password/recovery key, blob itu tak berguna — developer yang
///     punya akses Firestore pun hanya melihat ciphertext.
///
/// Kunci tak pernah dikirim ke server. Saat lupa password, data hanya bisa
/// dibuka dengan [recoveryKey] yang ditampilkan sekali saat setup.
class CryptoService {
  CryptoService._();

  static final CryptoService instance = CryptoService._();

  // Parameter PBKDF2. Iterasi tinggi memperlambat tebakan password.
  static const int _pbkdf2Iterations = 200000;
  static const int _saltLength = 16; // byte
  static const int _keyLength = 32; // byte (AES-256)

  final _aes = AesGcm.with256bits();
  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: _keyLength * 8,
  );

  /// Byte acak kriptografis sepanjang [length] (pakai CSPRNG platform).
  Future<List<int>> _randomBytes(int length) async {
    final key = SecretKeyData.random(length: length);
    return key.extractBytes();
  }

  /// Buat DEK acak baru. Dipanggil saat setup keamanan pertama.
  Future<SecretKey> generateDek() async =>
      SecretKeyData.random(length: _keyLength);

  /// Buat recovery key bentuk teks untuk ditampilkan ke pengguna (base32
  /// 128-bit, dikelompokkan dengan strip agar mudah disalin/diketik).
  Future<String> generateRecoveryKey() async {
    final bytes = await _randomBytes(16); // 128-bit
    final b32 = _base32Encode(bytes);
    final out = StringBuffer();
    for (var i = 0; i < b32.length; i++) {
      if (i > 0 && i % 4 == 0) out.write('-');
      out.write(b32[i]);
    }
    return out.toString();
  }

  /// Normalisasi recovery key input (buang spasi/strip/kapital).
  static String normalizeRecoveryKey(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');

  /// Turunkan KEK dari [secret] (password atau recovery key) + [salt].
  Future<SecretKey> _deriveKek(String secret, List<int> salt) async {
    final secretBytes = utf8.encode(secret);
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(secretBytes),
      nonce: salt,
    );
  }

  /// Bungkus DEK dengan [secret] (password). Menghasilkan blob kunci yang
  /// aman disimpan di server. Nonce GCM di-generate aman oleh paket.
  Future<KeyBlob> wrapDek(SecretKey dek, String secret) async {
    final salt = await _randomBytes(_saltLength);
    final kek = await _deriveKek(secret, salt);
    final dekBytes = await dek.extractBytes();
    final secretBox = await _aes.encrypt(dekBytes, secretKey: kek);
    return KeyBlob(
      salt: salt,
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      mac: secretBox.mac.bytes,
    );
  }

  /// Buka wrapper DEK dengan [secret]. Lempar [WrongKeyException] bila kunci
  /// salah (MAC tak cocok).
  Future<SecretKey> unwrapDek(KeyBlob blob, String secret) async {
    final kek = await _deriveKek(secret, blob.salt);
    final secretBox = SecretBox(
      blob.ciphertext,
      nonce: blob.nonce,
      mac: Mac(blob.mac),
    );
    try {
      final dekBytes = await _aes.decrypt(secretBox, secretKey: kek);
      return SecretKey(dekBytes);
    } on SecretBoxAuthenticationError {
      throw const WrongKeyException();
    }
  }

  /// Enkripsi payload JSON [AppState] dengan DEK. Nonce GCM acak aman.
  Future<EncryptedPayload> encrypt(
      Map<String, dynamic> json, SecretKey dek) async {
    final plaintext = utf8.encode(jsonEncode(json));
    final secretBox = await _aes.encrypt(plaintext, secretKey: dek);
    return EncryptedPayload(
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      mac: secretBox.mac.bytes,
    );
  }

  /// Dekripsi payload kembali menjadi Map JSON [AppState].
  /// Lempar [WrongKeyException] bila DEK salah.
  Future<Map<String, dynamic>> decrypt(
      EncryptedPayload payload, SecretKey dek) async {
    final secretBox = SecretBox(
      payload.ciphertext,
      nonce: payload.nonce,
      mac: Mac(payload.mac),
    );
    try {
      final plaintext = await _aes.decrypt(secretBox, secretKey: dek);
      return jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      throw const WrongKeyException();
    }
  }
}

/// Blob kunci: DEK yang sudah dibungkus (dienkripsi) oleh KEK. Aman disimpan
/// di server — tak berguna tanpa secret yang sesuai.
class KeyBlob {
  const KeyBlob({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  final List<int> salt;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> mac;

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'nonce': nonce,
        'ciphertext': ciphertext,
        'mac': mac,
      };

  factory KeyBlob.fromJson(Map<String, dynamic> json) => KeyBlob(
        salt: (json['salt'] as List).cast<int>(),
        nonce: (json['nonce'] as List).cast<int>(),
        ciphertext: (json['ciphertext'] as List).cast<int>(),
        mac: (json['mac'] as List).cast<int>(),
      );
}

/// Payload data terenkripsi (ciphertext + nonce + MAC).
class EncryptedPayload {
  const EncryptedPayload({
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> mac;

  Map<String, dynamic> toJson() => {
        'nonce': nonce,
        'ciphertext': ciphertext,
        'mac': mac,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        nonce: (json['nonce'] as List).cast<int>(),
        ciphertext: (json['ciphertext'] as List).cast<int>(),
        mac: (json['mac'] as List).cast<int>(),
      );
}

/// Sinyal DEK tak bisa dibuka dengan secret yang diberikan.
class WrongKeyException implements Exception {
  const WrongKeyException();
  @override
  String toString() => 'Kunci salah — tidak bisa membuka data.';
}

// Base32 (RFC 4648) alfabet, tanpa padding, untuk recovery key yang ringkas
// dan aman diketik manual.
const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

String _base32Encode(List<int> bytes) {
  final out = StringBuffer();
  var buffer = 0;
  var bitsLeft = 0;
  for (final b in bytes) {
    buffer = (buffer << 8) | (b & 0xff);
    bitsLeft += 8;
    while (bitsLeft >= 5) {
      bitsLeft -= 5;
      out.write(_base32Alphabet[(buffer >> bitsLeft) & 0x1f]);
    }
  }
  if (bitsLeft > 0) {
    out.write(_base32Alphabet[(buffer << (5 - bitsLeft)) & 0x1f]);
  }
  return out.toString();
}
