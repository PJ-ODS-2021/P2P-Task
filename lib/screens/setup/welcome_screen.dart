import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/setup/config_screen.dart';
import 'package:p2p_task/screens/setup/sync_config_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/widgets/fade_route_builder.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ConfigScreen(
      title: 'Welcome to the P2P Task Manager App 👋',
      onSubmit: () => _handleSubmit(context),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Choose a name:',
                ),
              ],
            ),
            TextFormField(
              validator: _validateName,
              decoration: InputDecoration(
                helperText:
                    'This name will be shown to other users when they connect with this device.',
                helperMaxLines: 2,
              ),
              controller: nameController,
              onFieldSubmitted: (value) => _handleSubmit(context),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateName(String? name) {
    if (name == null || name.isEmpty || name.length < 3) {
      return 'Name must be at least 3 characters long.';
    }

    return null;
  }

  void _handleSubmit(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final identityService =
          Provider.of<ChangeCallbackNotifier<IdentityService>>(
        context,
        listen: false,
      ).callbackProvider;
      await identityService.setName(nameController.text);
      _handleEncryptionKeys(identityService);
      await Navigator.pushReplacement(
        context,
        FadeRoute(
          (_) => SyncConfigScreen(),
        ),
      );
    }
  }

  void _handleEncryptionKeys(IdentityService identityService) async {
    if (await identityService.publicKeyPem == '') {
      var keyHelper = KeyHelper();
      var pair = keyHelper.generateRSAkeyPair();
      var privatekeyPem = keyHelper.encodePrivateKeyToPem(pair.privateKey);
      var publicKeyPem = keyHelper.encodePublicKeyToPem(pair.publicKey);
      await identityService.setPrivateKeyPem(privatekeyPem);
      await identityService.setPublicKeyPem(publicKeyPem);
    } else {
      // print public key for copy
      // new line has to be replaced manually by \r\n
      // -----BEGIN RSA PUBLIC KEY-----
      // MIIFog...
      // -----END RSA PUBLIC KEY-----
      // => -----BEGIN RSA PUBLIC KEY-----\r\nMIIFog...\r\n-----BEGIN RSA PUBLIC KEY-----
      print(await identityService.publicKeyPem);
    }
  }
}
