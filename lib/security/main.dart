import 'package:p2p_task/security/key_helper.dart';

const shortPlaintext =
    '{"typename":"DebugMessage","version":"0.1.0","object":{"value":"hello from the server"}}';

void main() {
  var keyHelper = KeyHelper();

  //generate new KeyPair
  final pair = keyHelper.generateRSAkeyPair();

// generate public and private key pem strings
  print(keyHelper.encodePrivateKeyToPem(pair.privateKey));
  print(keyHelper.encodePublicKeyToPem(pair.publicKey));

  //generate keys from pem strings
  var privateKey = keyHelper.decodePrivateKeyFromPem(_privateKey);
  var publicKey = keyHelper.decodePublicKeyFromPem(_publicKey);

  final cipherText = keyHelper.encrypt(publicKey, shortPlaintext);
  print(cipherText);

  final plainText = keyHelper.decrypt(privateKey, cipherText);
  print(plainText);
}

final String _publicKey = '''-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAjoMP2ZevqNiWmwKlYMU5UEvdBQvOq7xI0+nU5xembm5x0Ioi17CEzpUwPvwGG+RcrtIdGEDX5DCJImYQBky9n92D8NvOnz/c551zTCuRwDT0LEO3aQjW2KYKzrc2jPGv7d6Kj5wIzW2G9rEEjw71m29CI4TQB/MBJQciWQZGXysuq4DEaoeDXuavR4n1z6lc2IZH0o1BlqlDkNyNYYR3iLdn9tPmSwggnCdFKhpr4Vk83DmosSbyETMFPvd7DgHbeFSxfxcjfNXMJIQU/GFOySGgu0A0P3bmXPYu1mJ1Di/8O3Z7Y71ai+hSApkmGMBcXlJAnmww32F25uPv3UohuQIDAQAB
-----END RSA PUBLIC KEY-----''';

final String _privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIFpAIBAAKCAQEAjoMP2ZevqNiWmwKlYMU5UEvdBQvOq7xI0+nU5xembm5x0Ioi17CEzpUwPvwGG+RcrtIdGEDX5DCJImYQBky9n92D8NvOnz/c551zTCuRwDT0LEO3aQjW2KYKzrc2jPGv7d6Kj5wIzW2G9rEEjw71m29CI4TQB/MBJQciWQZGXysuq4DEaoeDXuavR4n1z6lc2IZH0o1BlqlDkNyNYYR3iLdn9tPmSwggnCdFKhpr4Vk83DmosSbyETMFPvd7DgHbeFSxfxcjfNXMJIQU/GFOySGgu0A0P3bmXPYu1mJ1Di/8O3Z7Y71ai+hSApkmGMBcXlJAnmww32F25uPv3UohuQKCAQBRi3T6UO1Wc/hZYj43DSMqav5g8MylP+t8NoR4ZvP4pIHDjgc52+tiOcONhrAILbdK4Td8tT3TeGI/qJ7qu+aVHy9sFpo4TVadwV5D63pOvP4qheTg2Qn2lawBdJxmMbU1Ku2mFuaChXWAmvG82hZ3hkYWBNz0b3vsMBTbU9fYhAH8YrkzdMuj5DA83kaBVAcN+FM6xaTchN8wf8wCOnLSr35JztDebA0YFeH3odqOmP/ee29soHjXqtvY2TW7SRqvvv/KZ2aaT3uaJWU+nE1AUU55QQ78SVPeyIsqRoXUTteuw4qYha8b3uwYdZcOBtTN85+WRB1qFkdJXErCfGgBAoIBAFGLdPpQ7VZz+FliPjcNIypq/mDwzKU/63w2hHhm8/ikgcOOBznb62I5w42GsAgtt0rhN3y1PdN4Yj+onuq75pUfL2wWmjhNVp3BXkPrek68/iqF5ODZCfaVrAF0nGYxtTUq7aYW5oKFdYCa8bzaFneGRhYE3PRve+wwFNtT19iEAfxiuTN0y6PkMDzeRoFUBw34UzrFpNyE3zB/zAI6ctKvfknO0N5sDRgV4feh2o6Y/957b2ygeNeq29jZNbtJGq++/8pnZppPe5olZT6cTUBRTnlBDvxJU97IiypGhdRO167DipiFrxve7Bh1lw4G1M3zn5ZEHWoWR0lcSsJ8aAECgYEA6ZgSxih1x6fuR6mUwIW6DHYgpMcsmkATRIxPbR48RxpLTXZZBX6w/juI/aQrROHfBhOi11sBpVvB/LnAs6OSKnBpcri1OiI3L8AWsV8yfP74xjzhRKQlqv8ymhKOI4bqOJdlHCO3dPeOBf9xB591+6RsaUNeutP2xOePoZlRNHkCgYEAnC51WuwKJe7XR+giBc4i68XhIwJ4OMk8GseAH+TdtpvKRw62f2MKIf6DLVphm2A6WqsFUJXMWg+OOjhynhjvEExPhLmbxHpx5ZchBDtVIbZKSPx56c76uSrVkBqEOjBux2XzU1EPe+Rf7B2T+9MB4vk/EaR7dF0l0Yn+1cUAh0ECgYEAqSMYrOyM44T/rlnmwEPTw8QgvM8Ox52Plfm2ZP8YjC9IyQzhRm5Gf77h4S3mupiFoOPE7AQUPAQlgPWKx0evxRTh9VQyvKYbqXJ/u+x/JSyFOxzHy6jDMX5YyGCZFLZSj6lnZ6mg44uABW3BDND0X8HdUZabV9G0gzxbrpnRx5kCgYEAghHfAp3ZxcWn3ObijtsiEiF2YmXIIeLV/6dueSFt1IriZ1NFgcnFwpHoRXkkGPaHIsOTZY2b5tVVqf8g1bIGRxiGkQ7TP0qKWJ8IjDGtsKnUK/y4u5P5EwUtXxn2TU/Qspehkh3MO23yxP3NJMiSpajWcab+eeapfFzksruiuQECgYEAhkLgEIufzw+quMV/VVE/Wal1I4/A5nHW9SUJj+IIEoz6JAvq6PcevDMjqr1fBun4QKLb95H61xWtdTA5B6WPzGTPX7xommOcy/qilmkVy7vErJyQy9+68HvIeUSDZBOjdUWhp6BBC9by6Dwb+XlzwdYtjTYrhd16oHdHFZiVx2E=
-----END RSA PRIVATE KEY-----''';
