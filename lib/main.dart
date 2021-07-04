import 'package:flutter/material.dart';
import 'package:p2p_task/app.dart';
import 'package:p2p_task/screens/setup/dependencies_provider.dart';
import 'package:p2p_task/screens/setup/landing_screen.dart';

void main() {
  runApp(
    DependenciesProvider(
      child: App(
        child: LandingScreen(),
      ),
    ),
  );
}
