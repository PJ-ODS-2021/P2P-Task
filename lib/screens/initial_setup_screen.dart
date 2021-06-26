import 'package:flutter/material.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:provider/provider.dart';
import 'package:p2p_task/security/key_helper.dart';

class InitialSetupDialog extends StatelessWidget with LogMixin {
  late final _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final keyHelper = KeyHelper();

  final title = 'P2P Task Manager';

  void _onSubmitPressed(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_nameController.text != '') {
        final identityService =
            Provider.of<ChangeCallbackNotifier<IdentityService>>(
          context,
          listen: false,
        ).callbackProvider;
        identityService.setName(_nameController.text);

        var pair = keyHelper.generateRSAkeyPair();
        var privatekeyPem = keyHelper.encodePrivateKeyToPem(pair.privateKey);
        var publicKeyPem = keyHelper.encodePublicKeyToPem(pair.publicKey);
        identityService.setPrivateKeyPem(privatekeyPem);
        identityService.setPublicKeyPem(publicKeyPem);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(title: title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(context)
            .callbackProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: identityService.privateKeyPem,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListTile(
              tileColor: Colors.white,
              title: Text('Error'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _showInitialDialog(context);
          } else {
            Future.microtask(
              () => Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      HomeScreen(title: title),
                  transitionDuration: Duration(seconds: 0),
                ),
              ),
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _showInitialDialog(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        title: Text('Welcome to the P2P Task Manager App 👋'),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 20.0,
            ),
            child: TextFormField(
              autofocus: true,
              onFieldSubmitted: (value) => _onSubmitPressed(context),
              decoration: InputDecoration(
                hintText: 'What\'s your name?',
                filled: true,
              ),
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name - it will be shown to other users when they connect with this device';
                }

                return null;
              },
            ),
          ),
          TextButton(
            onPressed: () => _onSubmitPressed(context),
            child: Text('Ok'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _nameController.dispose();
  }
}
