import 'package:flutter/cupertino.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/config/app_module.dart';
import 'package:p2p_task/screens/setup/splash_screen.dart';

class DependencyInitializerWidget extends StatelessWidget {
  final Widget child;

  DependencyInitializerWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      AppModule().initialize(Injector()),
      (_) => child,
      'Initializing dependencies...',
    );
  }
}
