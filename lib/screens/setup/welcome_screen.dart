import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/setup/config_view.dart';
import 'package:p2p_task/screens/setup/sync_config_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/widgets/fade_route_builder.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConfigView(
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
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 3) {
                    return 'Name must be at least 3 characters long.';
                  }

                  return null;
                },
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
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final identityService =
          Provider.of<ChangeCallbackNotifier<IdentityService>>(context,
                  listen: false)
              .callbackProvider;
      await identityService.setName(nameController.text);
      await Navigator.pushReplacement(
        context,
        FadeRoute(
          (_) => SyncConfigScreen(),
        ),
      );
    }
  }
}
