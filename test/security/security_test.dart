import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/web_socket_peer.dart';

void main() {
  var keyHelper = KeyHelper();
  var keyPair = keyHelper.generateRSAKeyPair();
  var message = 'Really private stuff';

  group('#security', () {
    test('encryption with keys', () {
      var encrypted = keyHelper.encrypt(keyPair.publicKey, message);
      expect(message, isNot(encrypted));
      var plain = keyHelper.decrypt(keyPair.privateKey, encrypted);
      expect(message, plain);
    });

    test('encryption with pem files', () {
      var publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);
      var privateKeyPem = keyHelper.encodePrivateKeyToPem(keyPair.privateKey);

      var encrypted = keyHelper.encryptWithPublicKeyPem(publicKeyPem, message);
      expect(message, isNot(encrypted));
      var plain = keyHelper.decryptWithPrivateKeyPem(privateKeyPem, encrypted);
      expect(message, plain);
    });

    test('sign and verify message', () {
      final publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);
      final signature = keyHelper.rsaSign(keyPair.privateKey, message);
      expect(keyHelper.rsaVerify(publicKeyPem, message, signature), true);
    });

    test('check signature of decrypted message', () {
      final publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);
      final sig = keyHelper.rsaSign(keyPair.privateKey, 'peerID');
      final introductionMessage = IntroductionMessage(
        peerID: 'peerID',
        name: 'name',
        ip: 'ip',
        port: 58241,
        publicKeyPem: keyHelper.encodePublicKeyToPem(keyPair.publicKey),
        signature: sig,
      );

      final peer = WebSocketPeer();
      peer.registerTypename<IntroductionMessage>(
        'IntroductionMessage',
        (json) => IntroductionMessage.fromJson(json),
      );

      final packet = peer.marshallPacket(introductionMessage);
      final encrypted = keyHelper.encryptWithPublicKeyPem(publicKeyPem, packet);
      expect(encrypted, isNot(packet));
      final decrypted = keyHelper.decrypt(keyPair.privateKey, encrypted);
      final decryptedPacket = Packet.fromJson(jsonDecode(decrypted));
      final plainMessage = IntroductionMessage.fromJson(decryptedPacket.object);

      expect(
        keyHelper.rsaVerify(
          publicKeyPem,
          plainMessage.peerID,
          plainMessage.signature,
        ),
        true,
      );
      expect(plainMessage.peerID, introductionMessage.peerID);
      expect(plainMessage.publicKeyPem, introductionMessage.publicKeyPem);
      expect(plainMessage.name, introductionMessage.name);
    });
  });
}
