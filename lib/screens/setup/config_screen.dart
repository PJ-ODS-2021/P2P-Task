import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final quarterPadding = screenWidth * 0.25 / 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('P2P Task Manager'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Container(
          height: screenHeight - 112,
          margin: const EdgeInsets.all(16.0),
          padding:
              EdgeInsets.symmetric(vertical: 32.0, horizontal: quarterPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(
                flex: 4,
              ),
              child,
              SizedBox(
                height: 16,
              ),
              Spacer(
                flex: 1,
              ),
              Center(
                child: MaterialButton(
                  padding: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  onPressed: onSubmit,
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  child: Text('OK'),
                ),
              ),
              Spacer(
                flex: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
