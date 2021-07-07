import 'package:p2p_task/security/key_helper.dart';
import 'dart:typed_data';

const shortPlaintext =
    '{"typename":"DebugMessage","version":"0.1.0","object":{"value":"hello from the server"}}';

void main() {
  var keyHelper = KeyHelper();

  //generate new KeyPair
  final pair = keyHelper.generateRSAkeyPair();

  var signature = keyHelper.rsaSign(pair.privateKey, shortPlaintext);

  print(signature);
  print("-----");

  print(keyHelper.rsaVerify(keyHelper.encodePublicKeyToPem(pair.publicKey),
      shortPlaintext, signature));

  // // generate public and private key pem strings
  // print(keyHelper.encodePrivateKeyToPem(pair.privateKey));
  // print(keyHelper.encodePublicKeyToPem(pair.publicKey));

  // // generate keys from pem strings
  // var privateKey = keyHelper.decodePrivateKeyFromPem(_privateKey);
  // var publicKey = keyHelper.decodePublicKeyFromPem(_publicKey);

  // final cipherText = keyHelper.encrypt(publicKey, shortPlaintext);
  // print(cipherText);

  // final plainText = keyHelper.decrypt(privateKey, cipherText);
  // print(plainText);
}

final String _privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIFogIBAAKCAQEAysvZaFue0O6iIHTHJRqgxoI54L70DeiXqoG5nTlANAB8B7TkpYhayzl+GPYnmNAr6C1VKY50Uaw1YbqYCsfpvjL4Gx8pCG/EP74yHVSAVuliuDWm64m3VdUg9DVcNsnRuXvbREAPxGVLoiKuXNQE8jMr7f5Fnw6bn/AXp/eZrNMMpEeTkQfJZJrmO2XL8xrbYXtD9FCSEFjmRg4E6RYEN
iGxAg8vdywVGdMBpeoAvc1rOOiG4m01LGaBShLms7mm0W54htcTaaFJwGjBqANnrjTJW0s0dIzcpCPr9HyDupS4d2znot5ChVAx/JpC0Z7uJQIrnfD8wt803oW7q/RhoQKCAQA1qaeIA+aMpvjj2cLwwJEWtlMWc7ElFQ09I0K4pfOlTxOC/o0aeHB+ImKJvGlR+JQFxiko6/c/vXAKwlOFVs01dUtN8frrrp
ehvnSIalnjpbJnyFq5LSIEZndn587U+Ka0jF/DOahycdOHveGh0sDUTlIrkgNeSYFI20GHQu+5WU72YDzNl29hAHfFNjy0AOZ6PZpikdKFPBx6/ykL0EZo6AAN1vpIJpmGEzUJCBFEI2JNJRhXJ9iCY0VscR72PDcYP6FP7FrhjideXOCQulPbyCA/5uwxVJvOLYIzyUynCKSu5UOFsc83Zf14MnJ+qlWVb+B
o4VKyQZaDAoI/8AXZAoIBADWpp4gD5oym+OPZwvDAkRa2UxZzsSUVDT0jQril86VPE4L+jRp4cH4iYom8aVH4lAXGKSjr9z+9cArCU4VWzTV1S03x+uuul6G+dIhqWeOlsmfIWrktIgRmd2fnztT4prSMX8M5qHJx04e94aHSwNROUiuSA15JgUjbQYdC77lZTvZgPM2Xb2EAd8U2PLQA5no9mmKR0oU8HHr/
KQvQRmjoAA3W+kgmmYYTNQkIEUQjYk0lGFcn2IJjRWxxHvY8Nxg/oU/sWuGOJ15c4JC6U9vIID/m7DFUm84tgjPJTKcIpK7lQ4Wxzzdl/Xgycn6qVZVv4GjhUrJBloMCgj/wBdkCgYEA6m4xnmjgLLAiRKyLWSxXqxejXT7BYPYj0qVMXKIF1KH83IGjOcF9aqnkfQyRAG8133NhxUDrP330ERVTsMVf1F6TF
G95eXD7DVSXISKk6Ta6oyqehziRhN1LLJhONuQWWBWPpjOGtVTutjm7n8h1xo3oIY19UVAlnGbcgi3yj7MCgYEA3XSKSws3zmqa7R0oTbh6lS8BUFAc47SEtM+dqtTvQ31gAswTYwx/nBu4JgBmC9kE3aIMPZjiTOunJBGTfq/cgPxlr7zSRGm1uOo8V20WY3NuwKhgNXuBRm9KHObNTu3beAmeZLsrMYeTdE
n4qqLv/jsdJD2Y9uMtMvTEdNQI/1sCgYAtVuCL1Za9rdcC1yggN/5AndK/nvqBiTlGbSfGpqNgC3A/KWdrLSvXbEI/mSWWIuwValhXcQXOgsqoXyqPfqzZAu2JP0IMJbi4TErqYqvoWuhf1EdSubMTMkVuu4os/ZIAuTLOHxsHiQSeA65w6bE1lI53psi86DZN+GrfVomaFwKBgGfLoKnttxljc/vg56wN5D6
aCnaXJgM/79dDXDXemco7ME3/UrLg/8quX1BIbYvuCs7Kjgws5RyCcxN/vW7qhGJcaljFGpSAK3FhMCkV8yFn0Cgygu1uVrgpn0YOk3oEGBKaB4hVBbiwP9eIeCmaNvwkvtLmoBRPhDbW7GGJpDHzAoGBAOj6GkL5ciyM1PNZUxTHiYrbZ+pIYBDIk92QHcf+KE3IFY5Tkt/AAKuzzYlIoyxP2zQ4bR0tE3PU
3vjwFTvnijd0GmSkMvteIkJjzOePYQWt/P2PNMBeW/vC5QhewahLj3Dn2+sxt6WXsYt4KTt17NsvOXF/6a2HqNxbxja/MrID
-----END RSA PRIVATE KEY-----''';

final String _publicKey =
    '-----BEGIN RSA PUBLIC KEY-----\r\nMIIBCgKCAQEAhplKnkTafnmKQKKbnSyl16Fl0t3ISjpNNZphLdmLH84YQeWM28Dh6w7xHeuJ/swXBjEUlHf9GlVo6BUqn5Yla7MY/8HPLiXvSYyp+KqfPdwrPKrp9JTbu3SaWPb+hJyQR1B/KJyRBOlas61Ogb7uZJK5zMI/AqVXKdra65T5LmlIQEzLHYgVPQgkthWzfHLIrSVvNrrh9/1FmiOhRcvTz9S934fhru75lXe9agvO/JdNC2hVxH7B20a0+EnwHcI7huPOKSsAzd6ayqtc3QSlSUQVZmvPTZulVqwnDFjOV3SJymu2nc2O/Om6UfWe+LHbUWvaT5dBw+lFmo8BcyvtAQIDAQAB\r\n-----END RSA PUBLIC KEY-----';
