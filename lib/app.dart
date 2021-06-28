import 'package:flutter/material.dart';

import 'config/style_constants.dart';

class App extends StatelessWidget {
  final Widget child;

  App({required child}) : child = child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'P2P Task Manager',
      theme: standardTheme,
      home: child,
    );
  }
}
