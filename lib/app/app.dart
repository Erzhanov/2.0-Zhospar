import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/platform/platform_adaptive.dart';
import '../core/theme/app_theme.dart';
import '../state/ai_chat_provider.dart';
import '../state/auth_provider.dart';
import '../state/music_provider.dart';
import '../state/task_provider.dart';
import '../state/theme_provider.dart';
import '../state/timer_provider.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';

/// Root provider graph for ZHOSPAR across iOS, Android, and Web.
class ZhosparRoot extends StatelessWidget {
  const ZhosparRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, task) => task!..syncAuthUser(auth.user?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AiChatProvider>(
          create: (_) => AiChatProvider(),
          update: (_, auth, chat) => chat!..syncAuthUser(auth.user?.id),
        ),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: const ZhosparApp(),
    );
  }
}

/// Top-level [MaterialApp] configuring adaptive scroll physics, system-synced
/// themes, edge-to-edge overlay contrast, and platform-native navigation transitions.
class ZhosparApp extends StatelessWidget {
  const ZhosparApp({super.key});

  static final SystemUiOverlayStyle _lightOverlay =
      SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static final SystemUiOverlayStyle _darkOverlay =
      SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (t) => t.themeMode,
    );
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? _darkOverlay : _lightOverlay,
      child: MaterialApp(
        title: 'ZHOSPAR',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AdaptiveScrollBehavior(),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
