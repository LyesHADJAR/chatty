import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyHelper {
  final X25519 _algo = X25519();
  final _secureStorage = const FlutterSecureStorage();

  Future<SimpleKeyPair> getOrGenerateKeyPair(String userID) async {
    final storedPrivateKey = await _secureStorage.read(
      key: '${userID}_private',
    );

    if (storedPrivateKey != null) {
      //if there is a private key stored, return it
      return _algo.newKeyPairFromSeed(base64Decode(storedPrivateKey));
    }

    //if no key, generate it using the X25519 algorithm
    final keyPair = await _algo.newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    //store the private key in the local secure storage
    await _secureStorage.write(
      key: '${userID}_private',
      value: base64Encode(privateKey),
    );

    //extract the public key of this user and store it in the firebase collection
    final publicKey = await keyPair.extractPublicKey();
    await FirebaseFirestore.instance.collection('Users').doc(userID).update({
      'x25519PublicKey': base64Encode(publicKey.bytes),
    });

    return keyPair;
  }

  Future<SimplePublicKey> getUserPublicKey(String otherUserID) async {
    // fetch the object from firestore
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(otherUserID)
        .get(const GetOptions(source: Source.server)); // Force fresh fetch

    final data = doc.data();
    if (data == null || !data.containsKey('x25519PublicKey')) {
      throw Exception("Missing 'x25519PublicKey' for user $otherUserID");
    }

    final encoded = data['x25519PublicKey'];
    return SimplePublicKey(base64Decode(encoded), type: KeyPairType.x25519);
  }

  Future<SecretKey> deriveSharedKey(String userID, String otherUserID) async {
    final userKeyPair = await getOrGenerateKeyPair(userID);
    final otherUserPublicKey = await getUserPublicKey(otherUserID);

    return _algo.sharedSecretKey(
      keyPair: userKeyPair,
      remotePublicKey: otherUserPublicKey,
    );
  }
}
