import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SimpleErrorPopupDialog extends StatelessWidget {
  final String title;
  final String message;

  SimpleErrorPopupDialog(this.title, this.message);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Ok'),
        ),
      ],
    );
  }
}
