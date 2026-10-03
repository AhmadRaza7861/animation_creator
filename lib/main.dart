import 'dart:io';
import 'package:dummy/utils/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/runtime_font_service.dart';
import 'features/projects/data/project_repository.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'utils/theme/customThems/app_bar_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.loadSavedLocale();
  RuntimeFontService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    CustomAppBarTheme.lightSystemUiOverlayStyle,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      exit(1);
    }
  };

  runApp(ProviderScope(child: MyApp(repository: ProjectRepository())));
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends ConsumerWidget {
  final ProjectRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Clipax',
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [routeObserver],
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? CustomAppBarTheme.darkSystemUiOverlayStyle
              : CustomAppBarTheme.lightSystemUiOverlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashScreen(repository: repository),
    );
  }
}

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
