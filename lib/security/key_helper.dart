import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart' as pc;
import 'package:asn1lib/asn1lib.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pem;

class KeyHelper {
  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> generateRSAkeyPair({
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

    final pair = keyGen.generateKeyPair();
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

    var blocks = _processInBlocks(
      encryptor,
      Uint8List.fromList(
        utf8.encode(dataToEncrypt),
      ),
    );

    return String.fromCharCodes(blocks);
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

  pc.RSAPrivateKey decodePrivateKeyFromPem(String priavateKeyPem) {
    try {
      var key = encrypt_pem.RSAKeyParser()
          .parse(priavateKeyPem.replaceAll('\\r\\n', '\n')) as pc.RSAPrivateKey;

      return key;
    } on FormatException catch (e) {
      return encrypt_pem.RSAKeyParser().parse(priavateKeyPem)
          as pc.RSAPrivateKey;
    }
  }

  pc.RSAPublicKey decodePublicKeyFromPem(String publicKeyPem) {
    try {
      var key = encrypt_pem.RSAKeyParser()
          .parse(publicKeyPem.replaceAll('\\r\\n', '\n')) as pc.RSAPublicKey;

      return key;
    } on FormatException catch (e) {
      return encrypt_pem.RSAKeyParser().parse(publicKeyPem) as pc.RSAPublicKey;
    }
  }

  String encryptWithPublicKeyPem(String publicKeyPem, String message) {
    var publicKey = decodePublicKeyFromPem(publicKeyPem);

    return encrypt(publicKey, message);
  }

  String decryptWithPrivateKeyPem(String privateKeyPem, String message) {
    var privateKey = decodePrivateKeyFromPem(privateKeyPem);

    return decrypt(privateKey, message);
  }

  String encodePublicKeyToPem(pc.RSAPublicKey publicKey) {
    var topLevel = ASN1Sequence();

    topLevel.add(
      ASN1Integer(publicKey.modulus!),
    );
    topLevel.add(
      ASN1Integer(publicKey.exponent!),
    );

    var dataBase64 = base64.encode(topLevel.encodedBytes);
    return '-----BEGIN RSA PUBLIC KEY-----\r\n$dataBase64\r\n-----END RSA PUBLIC KEY-----';
  }

  String encodePrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    var topLevel = ASN1Sequence();

    var version = ASN1Integer(BigInt.from(0));
    var modulus = ASN1Integer(privateKey.n!);
    var publicExponent = ASN1Integer(privateKey.exponent!);
    var privateExponent = ASN1Integer(privateKey.privateExponent!);
    var p = ASN1Integer(privateKey.p!);
    var q = ASN1Integer(privateKey.q!);
    var dP = privateKey.privateExponent! % (privateKey.p! - BigInt.from(1));
    var exp1 = ASN1Integer(dP);
    var dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.from(1));
    var exp2 = ASN1Integer(dQ);
    var iQ = privateKey.q!.modInverse(privateKey.p!);
    var co = ASN1Integer(iQ);

    topLevel.add(version);
    topLevel.add(modulus);
    topLevel.add(publicExponent);
    topLevel.add(privateExponent);
    topLevel.add(p);
    topLevel.add(q);
    topLevel.add(exp1);
    topLevel.add(exp2);
    topLevel.add(co);

    var dataBase64 = base64.encode(topLevel.encodedBytes);

    return '-----BEGIN RSA PRIVATE KEY-----\r\n$dataBase64\r\n-----END RSA PRIVATE KEY-----';
  }
}
