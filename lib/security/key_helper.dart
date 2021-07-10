import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:asn1lib/asn1lib.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pem;

class KeyHelper with LogMixin {
  static const _algorithmIdentifier = '0609608648016503040201';

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> generateRSAKeyPair({
    int bitLength = 2048,
  }) {
    // higher value of bitLength will lower the performance

    final keyGen = pc.KeyGenerator('RSA');
    keyGen.init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        _generateeSecureRandom(),
      ),
    );

    logger.info('Generating key pair');
    final start = DateTime.now();
    final pair = keyGen.generateKeyPair();
    final end = DateTime.now();
    logger.info('Generating key pair (took ${end.difference(start)})');

    final myPublic = pair.publicKey as pc.RSAPublicKey;
    final myPrivate = pair.privateKey as pc.RSAPrivateKey;

    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      myPublic,
      myPrivate,
    );
  }

  String decrypt(pc.RSAPrivateKey myPrivate, String cipherText) {
    final decryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(
        false,
        pc.PrivateKeyParameter<pc.RSAPrivateKey>(myPrivate),
      );

    return String.fromCharCodes(
      _processInBlocks(
        decryptor,
        Uint8List.fromList(cipherText.codeUnits),
      ),
    );
  }

  String decryptUnit8List(pc.RSAPrivateKey myPrivate, Uint8List cipherText) {
    final decryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(
        false,
        pc.PrivateKeyParameter<pc.RSAPrivateKey>(myPrivate),
      );

    return String.fromCharCodes(
      _processInBlocks(
        decryptor,
        cipherText,
      ),
    );
  }

  Uint8List _processInBlocks(pc.AsymmetricBlockCipher engine, Uint8List input) {
    final numBlocks = input.length ~/ engine.inputBlockSize +
        ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

    final output = Uint8List(numBlocks * engine.outputBlockSize);

    var inputOffset = 0;
    var outputOffset = 0;
    while (inputOffset < input.length) {
      final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
          ? engine.inputBlockSize
          : input.length - inputOffset;

      outputOffset += engine.processBlock(
        input,
        inputOffset,
        chunkSize,
        output,
        outputOffset,
      );

      inputOffset += chunkSize;
    }

    return (output.length == outputOffset)
        ? output
        : output.sublist(0, outputOffset);
  }

  String encrypt(pc.RSAPublicKey myPublic, String dataToEncrypt) {
    final encryptor = pc.OAEPEncoding(
      pc.RSAEngine(),
    )..init(
        true,
        pc.PublicKeyParameter<pc.RSAPublicKey>(myPublic),
      );

    final blocks = _processInBlocks(
      encryptor,
      Uint8List.fromList(
        utf8.encode(dataToEncrypt),
      ),
    );

    return String.fromCharCodes(blocks);
  }

  Uint8List rsaSign(pc.RSAPrivateKey privateKey, String dataToSign) {
    final signer = pc.RSASigner(pc.SHA256Digest(), _algorithmIdentifier);

    signer.init(true, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));

    final sig = signer.generateSignature(Uint8List.fromList(
      utf8.encode(dataToSign),
    ));

    return sig.bytes;
  }

  bool rsaVerify(String publicKeyPem, String signedData, Uint8List signature) {
    final publicKey = decodePublicKeyFromPem(publicKeyPem);

    final sig = pc.RSASignature(signature);

    final verifier = pc.RSASigner(pc.SHA256Digest(), _algorithmIdentifier);

    verifier.init(
      false,
      pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey),
    );

    try {
      return verifier.verifySignature(
        Uint8List.fromList(signedData.codeUnits),
        sig,
      );
    } on ArgumentError {
      return false;
    }
  }

  pc.SecureRandom _generateeSecureRandom() {
    final secureRandom = pc.FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(
        seedSource.nextInt(255),
      );
    }
    secureRandom.seed(
      pc.KeyParameter(
        Uint8List.fromList(seeds),
      ),
    );

    return secureRandom;
  }

  pc.RSAPrivateKey decodePrivateKeyFromPem(String privateKeyPem) {
    try {
      final key = encrypt_pem.RSAKeyParser().parse(_sanitizePem(privateKeyPem))
          as pc.RSAPrivateKey;

      return key;
    } on FormatException {
      return encrypt_pem.RSAKeyParser().parse(privateKeyPem)
          as pc.RSAPrivateKey;
    }
  }

  String _sanitizePem(String pem) {
    return pem.replaceAll('\\r\\n', '\n');
  }

  pc.RSAPublicKey decodePublicKeyFromPem(String publicKeyPem) {
    try {
      final key = encrypt_pem.RSAKeyParser().parse(_sanitizePem(publicKeyPem))
          as pc.RSAPublicKey;

      return key;
    } on FormatException {
      try {
        final key =
            encrypt_pem.RSAKeyParser().parse(publicKeyPem) as pc.RSAPublicKey;
        ;

        return key;
      } on FormatException {
        return encrypt_pem.RSAKeyParser().parse(publicKeyPem)
            as pc.RSAPublicKey;
      }
    }
  }

  String encryptWithPublicKeyPem(String publicKeyPem, String message) =>
      encrypt(decodePublicKeyFromPem(publicKeyPem), message);

  String decryptWithPrivateKeyPem(String privateKeyPem, String message) =>
      decrypt(decodePrivateKeyFromPem(privateKeyPem), message);

  String encodePublicKeyToPem(pc.RSAPublicKey publicKey) {
    final topLevel = ASN1Sequence();

    topLevel.add(
      ASN1Integer(publicKey.modulus!),
    );
    topLevel.add(
      ASN1Integer(publicKey.exponent!),
    );

    final dataBase64 = base64.encode(topLevel.encodedBytes);

    return _wrapKey(dataBase64, 'PUBLIC');
  }

  String _wrapKey(String data, String type) {
    return '-----BEGIN RSA $type KEY-----\r\n$data\r\n-----END RSA $type KEY-----';
  }

  String encodePrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    final topLevel = ASN1Sequence();

    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(privateKey.n!);
    final publicExponent = ASN1Integer(privateKey.exponent!);
    final privateExponent = ASN1Integer(privateKey.privateExponent!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.from(1));
    final exp1 = ASN1Integer(dP);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.from(1));
    final exp2 = ASN1Integer(dQ);
    final iQ = privateKey.q!.modInverse(privateKey.p!);
    final co = ASN1Integer(iQ);

    topLevel.add(version);
    topLevel.add(modulus);
    topLevel.add(publicExponent);
    topLevel.add(privateExponent);
    topLevel.add(p);
    topLevel.add(q);
    topLevel.add(exp1);
    topLevel.add(exp2);
    topLevel.add(co);

    final dataBase64 = base64.encode(topLevel.encodedBytes);

    return _wrapKey(dataBase64, 'PRIVATE');
  }
}
