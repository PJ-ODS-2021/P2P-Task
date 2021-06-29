import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/setup/scroll_column_expandable.dart';

class ConfigScreen extends StatelessWidget {
  final Widget child;
  final String title;
  final Function() onSubmit;

  ConfigScreen({
    required this.child,
    required this.title,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(18.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: ScrollColumnExpandable(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _buildTitle(),
              ),
              Spacer(),
              Container(
                constraints: BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: child,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _buildButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return MaterialButton(
      padding: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      onPressed: onSubmit,
      color: Theme.of(context).accentColor,
      textColor: Colors.white,
      child: Text('OK'),
    );
  }
}
