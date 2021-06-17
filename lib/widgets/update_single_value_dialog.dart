import 'package:flutter/material.dart';

class UpdateSingleValueDialog extends StatelessWidget {
  final controller = TextEditingController();
  final Widget title;
  final Function(String value) onSave;

  UpdateSingleValueDialog(this.title, this.onSave);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: TextFormField(
        autofocus: true,
        controller: controller,
        onFieldSubmitted: (value) => _onSubmit(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _onSubmit(context, controller.text),
          child: Text('Save'),
        ),
      ],
    );
  }

  void _onSubmit(BuildContext context, String value) {
    onSave(value);
    Navigator.pop(context);
  }
}
