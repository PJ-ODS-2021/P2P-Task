import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/screens/setup/database_setup_screen.dart';
import 'package:p2p_task/screens/setup/dependencies_initalizor.dart';
import 'package:p2p_task/screens/setup/splash_screen.dart';
import 'package:p2p_task/utils/shared_preferences_keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SplashScreen<SharedPreferences>(
      SharedPreferences.getInstance(),
      (sharedPreferences) {
        final hasAlreadyVisited = sharedPreferences
                .containsKey(SharedPreferencesKeys.databasePath.value) ||
            sharedPreferences.containsKey(SharedPreferencesKeys.inMemory.value);
        final isDesktop = !kIsWeb && !(Platform.isIOS || Platform.isAndroid);

        return hasAlreadyVisited || !isDesktop
            ? DependenciesInitializor(
                child: HomeScreen(title: 'P2P Task Manager'),
              )
            : SplashScreen<Directory>(
                getApplicationDocumentsDirectory(),
                (directory) => DatabaseSetupScreen(directory),
                'Retrieve default directory...',
              );
      },
      'Loading...',
    );
  }
}
