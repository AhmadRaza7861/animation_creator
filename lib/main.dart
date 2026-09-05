import 'dart:io';
import 'package:dummy/utils/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/projects/data/project_repository.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      exit(1);
    }
  };

  runApp(
    ProviderScope(
      child: MyApp(repository: ProjectRepository()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ProjectRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clipax',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorKey: NavigationService.navigatorKey,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(repository: repository),
    );
  }
}


class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
