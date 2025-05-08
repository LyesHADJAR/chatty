import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  final AesGcm _aes = AesGcm.with256bits();

  Future<Map<String, dynamic>> encryptMessage(
    String rawMessage,
    SecretKey secretKey,
  ) async {
    final nonce = _aes.newNonce();

    final encryptedMessage = await _aes.encrypt(
      utf8.encode(rawMessage),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'ciphertext': base64Encode(encryptedMessage.cipherText),
      'nonce': base64Encode(encryptedMessage.nonce),
      'mac': base64Encode(encryptedMessage.mac.bytes),
    };
  }

  Future<String> decryptMessage(
    Map<String, dynamic> encryptedData,
    SecretKey secretKey,
  ) async {
    final secretBox = SecretBox(
      base64Decode(encryptedData['ciphertext']),
      nonce: base64Decode(encryptedData['nonce']),
      mac: Mac(base64Decode(encryptedData['mac'])),
    );

    final rawMessage = await _aes.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(rawMessage);
  }
}
