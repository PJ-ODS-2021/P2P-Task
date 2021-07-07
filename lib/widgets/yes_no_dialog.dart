import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class YesNoDialog extends StatelessWidget {
  // ignore: long-parameter-list
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? description,
    String? yesText,
    String? noText,
  }) {
    return showDialog(
      context: context,
      builder: (_) => YesNoDialog(
        title: title,
        description: description,
        yesText: yesText,
        noText: noText,
      ),
    );
  }

  final String? title;
  final String? description;
  final String? yesText;
  final String? noText;

  YesNoDialog({this.title, this.description, this.yesText, this.noText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Are you sure?'),
      content: Text(
        description ?? '',
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(true);
          },
          child: Text(yesText ?? 'Yes'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(false);
          },
          child: Text(noText ?? 'No'),
        ),
      ],
    );
  }
}
