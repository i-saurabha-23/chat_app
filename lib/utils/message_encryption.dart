import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;

import '../constants/encryption_keys.dart';

class MessageEncryption {
  MessageEncryption._();

  static final encrypt.Key _key = _buildKey();
  static final encrypt.Encrypter _encrypter = encrypt.Encrypter(
    encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );
  static final Random _random = Random.secure();

  static Map<String, String> encryptText(String value) {
    final encrypt.IV iv = encrypt.IV(_randomBytes(16));
    final encrypt.Encrypted encrypted = _encrypter.encrypt(value, iv: iv);
    return <String, String>{'cipherText': encrypted.base64, 'iv': iv.base64};
  }

  static String decryptText({
    required String cipherText,
    required String ivBase64,
    bool fallbackToRawWhenInvalid = true,
  }) {
    if (cipherText.trim().isEmpty) {
      return '';
    }

    if (ivBase64.trim().isEmpty) {
      return fallbackToRawWhenInvalid ? cipherText : '';
    }

    try {
      final encrypt.IV iv = encrypt.IV.fromBase64(ivBase64);
      return _encrypter.decrypt64(cipherText, iv: iv);
    } catch (_) {
      return fallbackToRawWhenInvalid ? cipherText : '';
    }
  }

  static encrypt.Key _buildKey() {
    final List<int> bytes = utf8.encode(AES_KEY);
    if (bytes.length == 16 || bytes.length == 24 || bytes.length == 32) {
      return encrypt.Key(Uint8List.fromList(bytes));
    }

    if (bytes.length > 32) {
      return encrypt.Key(Uint8List.fromList(bytes.sublist(0, 32)));
    }

    final Uint8List padded = Uint8List(32);
    padded.setRange(0, bytes.length, bytes);
    return encrypt.Key(padded);
  }

  static Uint8List _randomBytes(int length) {
    final Uint8List bytes = Uint8List(length);
    for (int index = 0; index < length; index++) {
      bytes[index] = _random.nextInt(256);
    }
    return bytes;
  }
}
