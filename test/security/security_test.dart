import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/web_socket_peer.dart';

void main() {
  var keyHelper = KeyHelper();
  var keyPair = keyHelper.generateRSAkeyPair();
  var message = 'Really private stuff';

  group('#security', () {
    test('encryption with keys', () {
      var encrypted = keyHelper.encrypt(keyPair.publicKey, message);
      expect(message != encrypted, true);
      var plain = keyHelper.decrypt(keyPair.privateKey, encrypted);

      expect(message == plain, true);
    });

    test('encryption with pem files', () {
      var publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);
      var privateKeyPem = keyHelper.encodePrivateKeyToPem(keyPair.privateKey);

      var encrypted = keyHelper.encryptWithPublicKeyPem(publicKeyPem, message);
      expect(message != encrypted, true);
      var plain = keyHelper.decryptWithPrivateKeyPem(privateKeyPem, encrypted);

      expect(message == plain, true);
    });

    test('sign and verify message', () {
      var publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);
      var signature = keyHelper.rsaSign(keyPair.privateKey, message);
      expect(keyHelper.rsaVerify(publicKeyPem, message, signature), true);
    });

    test('check signature of decrpyted message', () {
      var publicKeyPem = keyHelper.encodePublicKeyToPem(keyPair.publicKey);

      var sig = keyHelper.rsaSign(keyPair.privateKey, 'peerID');

      var introductionMessage = IntroductionMessage(
        'peerID',
        'name',
        'ip',
        58241,
        keyHelper.encodePublicKeyToPem(keyPair.publicKey),
        sig,
      );

      final peer = WebSocketPeer();

      peer.registerTypename<IntroductionMessage>(
        'IntroductionMessage',
        (json) => IntroductionMessage.fromJson(json),
      );

      var packet = peer.marshallPacket(introductionMessage);
      var encrypted = keyHelper.encryptWithPublicKeyPem(publicKeyPem, packet);

      expect(encrypted != packet, true);

      var decrypted = keyHelper.decrypt(keyPair.privateKey, encrypted);
      var decryptedPacket = Packet.fromJson(jsonDecode(decrypted));

      var plainMessage = IntroductionMessage.fromJson(decryptedPacket.object);

      expect(
        keyHelper.rsaVerify(
          publicKeyPem,
          plainMessage.peerID,
          plainMessage.signature,
        ),
        true,
      );
      expect(plainMessage.peerID, introductionMessage.peerID);
      expect(plainMessage.publicKey, introductionMessage.publicKey);
      expect(plainMessage.name, introductionMessage.name);
    });
  });
}
