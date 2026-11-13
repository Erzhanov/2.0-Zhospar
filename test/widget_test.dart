import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhospar_app/app/router/app_router.dart';
import 'package:zhospar_app/app/router/app_routes.dart';
import 'package:zhospar_app/core/i18n/language_provider.dart';
import 'package:zhospar_app/core/platform/platform_adaptive.dart';
import 'package:zhospar_app/core/theme/app_theme.dart';
import 'package:zhospar_app/core/utils/week_utils.dart';
import 'package:zhospar_app/data/models/daily_reflection.dart';
import 'package:zhospar_app/data/models/task.dart';
import 'package:zhospar_app/data/models/week.dart';
import 'package:zhospar_app/data/models/weekly_review.dart';
import 'package:zhospar_app/data/services/auth_service.dart';
import 'package:zhospar_app/data/services/task_service.dart';
import 'package:zhospar_app/data/services/week_service.dart';
import 'package:zhospar_app/data/services/reminder_service.dart';
import 'package:zhospar_app/data/services/widget_data_service.dart';
import 'package:zhospar_app/features/analytics/analytics_screen.dart';
import 'package:zhospar_app/features/archive/archive_screen.dart';
import 'package:zhospar_app/features/auth/auth_screen.dart';
import 'package:zhospar_app/features/dashboard/dashboard_screen.dart';
import 'package:zhospar_app/features/dashboard/widgets/task_detail_sheet.dart';
import 'package:zhospar_app/features/dashboard/widgets/task_form_sheet.dart';
import 'package:zhospar_app/features/dashboard/widgets/task_item_widget.dart';
import 'package:zhospar_app/features/landing/landing_screen.dart';
import 'package:zhospar_app/features/settings/settings_screen.dart';
import 'package:zhospar_app/features/shell/app_shell.dart';
import 'package:zhospar_app/features/shell/widgets/animated_bottom_nav_bar.dart';
import 'package:zhospar_app/features/shell/widgets/mobile_more_sheet.dart';
import 'package:zhospar_app/features/shell/widgets/top_app_bar.dart';
import 'package:zhospar_app/features/timer/timer_screen.dart';
import 'package:zhospar_app/shared/widgets/floating_motion.dart';
import 'package:zhospar_app/state/ai_chat_provider.dart';
import 'package:zhospar_app/state/auth_provider.dart';
import 'package:zhospar_app/state/gamification_provider.dart';
import 'package:zhospar_app/state/music_provider.dart';
import 'package:zhospar_app/state/task_provider.dart';
import 'package:zhospar_app/state/theme_provider.dart';
import 'package:zhospar_app/state/timer_provider.dart';

class _FakeAuthService implements AuthService {
  final _controller = StreamController<AuthState>.broadcast();
  Session? _session;
  bool admin = false;

  _FakeAuthService({Session? initialSession}) : _session = initialSession;

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  bool get isAuthenticated => _session != null;

  @override
  Future<bool> checkIsAdmin() async => admin;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final user = User(
      id: 'user-123',
      appMetadata: const {},
      userMetadata: const {'display_name': 'Ayan'},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      email: email.trim(),
    );
    _session = Session(
      accessToken: 'token-abc',
      tokenType: 'bearer',
      user: user,
    );
    _controller.add(AuthState(AuthChangeEvent.signedIn, _session));
    return AuthResponse(session: _session, user: user);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<User?> updateDisplayName(String displayName) async {
    final prev = _session?.user;
    if (prev == null) return null;
    final updated = User(
      id: prev.id,
      appMetadata: prev.appMetadata,
      userMetadata: {'display_name': displayName.trim()},
      aud: prev.aud,
      createdAt: prev.createdAt,
      email: prev.email,
    );
    _session = Session(
      accessToken: _session!.accessToken,
      tokenType: _session!.tokenType,
      user: updated,
    );
    return updated;
  }
}

class _FakeWeekService implements WeekService {
  final List<WeekModel>? weeksOverride;

  _FakeWeekService({this.weeksOverride});

  @override
  Future<List<WeekModel>> getAllWeeks() async =>
      weeksOverride ??
      [
        WeekModel(
          id: 'w1',
          userId: 'user-123',
          weekStartDate: '2026-11-09',
          quote: 'Keep going',
        ),
      ];

  @override
  Future<WeekModel?> getOrCreateWeek([String? weekStartDate]) async =>
      WeekModel(
        id: 'w1',
        userId: 'user-123',
        weekStartDate: weekStartDate ?? '2026-11-09',
        quote: 'Keep going',
      );

  @override
  Future<DailyReflectionModel?> getReflection(
    String weekId,
    int dayOfWeek,
  ) async =>
      null;

  @override
  Future<List<DailyReflectionModel>> getReflectionsForWeek(
    String weekId,
  ) async =>
      [];

  @override
  Future<WeeklyReviewModel?> getWeeklyReview(String weekId) async => null;

  @override
  Future<void> saveReflection(String weekId, int dayOfWeek, String text) async {}

  @override
  Future<void> saveWeeklyReview({
    required String weekId,
    required String learnedText,
    required String goodText,
    required String hardText,
    required String changeText,
    required List<String> nextGoals,
  }) async {}

  @override
  Future<void> updateWeekQuote(String weekId, String quote) async {}
}

class _FakeTaskService implements TaskService {
  final List<TaskModel> seedTasks;
  final Map<String, List<TaskModel>>? weekTasksMap;
  final List<Map<String, dynamic>> updatedTaskCalls = [];
  final List<String> deletedTaskIds = [];
  late final List<TaskModel> _tasks = List.of(seedTasks);

  _FakeTaskService([this.seedTasks = const [], this.weekTasksMap]);

  @override
  Future<TaskModel?> addTask({
    required String weekId,
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    String priority = 'med',
    String? dueTime,
  }) async {
    final created = TaskModel(
      id: 't-new',
      weekId: weekId,
      userId: 'user-123',
      dayOfWeek: dayOfWeek,
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueTime: dueTime,
    );
    _tasks.add(created);
    return created;
  }

  @override
  Future<void> syncPendingQueue() async {}

  @override
  Future<int> copyIncompleteTasks(
    String currentWeekId,
    String currentWeekStartDate,
  ) async =>
      0;

  @override
  Future<void> deleteTask(String id) async {
    deletedTaskIds.add(id);
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<TaskModel>> getTasksForWeek(String weekId) async =>
      List.of(_tasks);

  @override
  Future<Map<String, List<TaskModel>>> getTasksForWeeks(
    List<String> weekIds,
  ) async {
    if (weekTasksMap != null) {
      return {
        for (final id in weekIds) id: List.of(weekTasksMap![id] ?? const []),
      };
    }
    return {for (final id in weekIds) id: List.of(_tasks)};
  }

  @override
  Future<int> replaceTasksForWeek(
    String weekId,
    List<Map<String, dynamic>> tasks,
  ) async =>
      tasks.length;

  @override
  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    updatedTaskCalls.add({'id': id, ...updates});
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final cur = _tasks[idx];
      _tasks[idx] = cur.copyWith(
        title: updates['title'] as String? ?? cur.title,
        description: updates.containsKey('description')
            ? updates['description'] as String?
            : cur.description,
        category: updates.containsKey('category')
            ? updates['category'] as String?
            : cur.category,
        priority: updates['priority'] as String? ?? cur.priority,
        dueTime: updates.containsKey('due_time')
            ? updates['due_time'] as String?
            : cur.dueTime,
        status: updates['status'] as String? ?? cur.status,
      );
    }
  }
}

Widget _buildTestApp({
  required AuthProvider authProvider,
  TaskProvider? taskProvider,
  ThemeProvider? themeProvider,
  TimerProvider? timerProvider,
  TargetPlatform? platform,
  Size viewport = const Size(390, 844),
  String initialRoute = AppRoutes.root,
}) {
  final tProvider = taskProvider ??
      TaskProvider(
        taskService: _FakeTaskService([
          TaskModel(
            id: 'task-1',
            weekId: 'w1',
            userId: 'user-123',
            dayOfWeek: DateTime.now().weekday,
            title: 'Write tests',
            category: 'Жоба',
            priority: 'high',
            dueTime: '10:00',
          ),
        ]),
        weekService: _FakeWeekService(),
      );
  final thProvider = themeProvider ?? ThemeProvider();
  final tmProvider = timerProvider ?? TimerProvider();
  final lightTheme = platform != null
      ? AppTheme.light().copyWith(platform: platform)
      : AppTheme.light();
  final darkTheme = platform != null
      ? AppTheme.dark().copyWith(platform: platform)
      : AppTheme.dark();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider<ThemeProvider>.value(value: thProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ChangeNotifierProvider(create: (_) => ReminderService()),
      ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
        create: (_) => tProvider,
        update: (_, auth, prev) {
          final p = prev ?? tProvider;
          p.syncAuthUser(auth.isAuthenticated ? auth.user?.id : null);
          return p;
        },
      ),
      ChangeNotifierProxyProvider<AuthProvider, AiChatProvider>(
        create: (_) => AiChatProvider(),
        update: (_, auth, prev) {
          final p = prev ?? AiChatProvider();
          p.syncAuthUser(auth.isAuthenticated ? auth.user?.id : null);
          return p;
        },
      ),
      ChangeNotifierProvider<TimerProvider>.value(value: tmProvider),
      ChangeNotifierProvider(create: (_) => MusicProvider()),
    ],
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQueryData(size: viewport),
        child: MaterialApp(
          scrollBehavior: const AdaptiveScrollBehavior(),
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: Provider.of<ThemeProvider>(context).themeMode,
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppMotion.enableContinuousDrift = false;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.zhospar.zhospar_app/widget'),
      (call) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    PlatformAdaptive.hapticsNotifier.value = true;
  });

  testWidgets(
    'Unauthenticated users see AuthScreen as default initial view and redirect on login',
    (tester) async {
      final authService = _FakeAuthService();
      final authProvider = AuthProvider(authService: authService);

      await tester.pumpWidget(_buildTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      // Default view is AuthScreen, not LandingScreen or DashboardScreen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(LandingScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);

      // No dead back button when AuthScreen is root
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      // Fill email and password and submit login
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ayan@example.com');
      await tester.enterText(fields.at(1), 'secret123');
      final loginSubmit = find.byType(ElevatedButton).first;
      await tester.ensureVisible(loginSubmit);
      await tester.tap(loginSubmit);
      await tester.pumpAndSettle();

      // Redirected to main AppShell / DashboardScreen
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.accessToken, 'token-abc');
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Protected sub-route redirects unauthenticated user to AuthScreen',
    (tester) async {
      final authProvider = AuthProvider(authService: _FakeAuthService());

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          initialRoute: AppRoutes.settings,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Sub-pages show sticky TopAppBar with dynamic title & Back button that pops stack',
    (tester) async {
      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(_buildTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      // Primary AppShell omits TopAppBar; pushed sub-pages render TopAppBar with Back
      expect(find.byType(TopAppBar), findsNothing);

      expect(find.byType(AppShell), findsOneWidget);

      // Open More sheet -> navigate to AnalyticsScreen sub-page
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.byIcon(Icons.bar_chart_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsScreen), findsOneWidget);
      final backIcon = find.byIcon(Icons.arrow_back_rounded);
      expect(backIcon, findsOneWidget);
      final backButton = find.ancestor(
        of: backIcon,
        matching: find.byType(InkWell),
      );
      expect(
        tester.getSize(backButton.first).width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(backButton.first).height,
        greaterThanOrEqualTo(44),
      );

      // Tap Back -> pops back to AppShell
      await tester.tap(backIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);

      // Open More sheet -> navigate to TimerScreen
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.byIcon(Icons.timer_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimerScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Back button on TimerScreen pops back to AppShell
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TimerScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    },
  );

  testWidgets(
    'AnimatedBottomNavBar switches tabs smoothly and enforces >=44x44px touch targets on 360px mobile viewport',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          viewport: const Size(360, 780),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedBottomNavBar), findsOneWidget);
      expect(find.byType(TaskItemWidget), findsOneWidget);

      // Verify bottom nav bar height >= 44px, inline edit/delete removed, and view icon >= 44x44px
      final navSize = tester.getSize(find.byType(AnimatedBottomNavBar));
      expect(navSize.height, greaterThanOrEqualTo(44));
      expect(
        find.descendant(
          of: find.byType(AnimatedBottomNavBar),
          matching: find.byIcon(Icons.bar_chart_outlined),
        ),
        findsNothing,
      );

      expect(
        find.descendant(
          of: find.byType(TaskItemWidget),
          matching: find.byIcon(Icons.edit_outlined),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(TaskItemWidget),
          matching: find.byIcon(Icons.delete_outline_rounded),
        ),
        findsNothing,
      );

      final taskViewButton = find.descendant(
        of: find.byType(TaskItemWidget),
        matching: find.ancestor(
          of: find.byIcon(Icons.visibility_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(
        tester.getSize(taskViewButton.first).width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(taskViewButton.first).height,
        greaterThanOrEqualTo(44),
      );

      // Tap Week Plan tab and verify Day/Week toggle works on 360px screen
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Апталық Жоспар'), findsOneWidget);

      // Tap AI Assistant tab (slot 2)
      await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
      await tester.pumpAndSettle();
      expect(find.text('AI Көмекші'), findsWidgets);

      // Tap Settings tab (slot 3) in bottom bar and verify confirmed sign-out returns to AuthScreen
      await tester.tap(find.byIcon(Icons.settings_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      final logoutButton = find.byIcon(Icons.logout_rounded).last;
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Шығу').last);
      await tester.pumpAndSettle();
      expect(authProvider.isAuthenticated, isFalse);
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );

  test('TaskProvider syncAuthUser clears cached tasks on sign out', () async {
    final taskProvider = TaskProvider(
      taskService: _FakeTaskService([
        TaskModel(
          id: 't1',
          weekId: 'w1',
          userId: 'user-123',
          dayOfWeek: 1,
          title: 'Sample',
        ),
      ]),
      weekService: _FakeWeekService(),
    );

    taskProvider.syncAuthUser('user-123');
    await Future<void>.delayed(Duration.zero);
    expect(taskProvider.tasks.length, 1);

    taskProvider.syncAuthUser(null);
    expect(taskProvider.tasks, isEmpty);
    expect(taskProvider.currentWeek, isNull);
  });

  testWidgets(
    'AuthScreen renders with zero overflow on narrow 320px phone viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = AuthProvider(authService: _FakeAuthService());
      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          viewport: const Size(320, 740),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );

  testWidgets(
    'TimerScreen renders cleanly on 320px phone and Back button falls back to home when stack root',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          viewport: const Size(320, 740),
          initialRoute: AppRoutes.timer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimerScreen), findsOneWidget);

      // Tapping Back when TimerScreen is stack root redirects to AppShell/Home
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    },
  );

  testWidgets(
    'Dark mode Deep Space Anti-Gravity glass surfaces and More sheet render cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Dark mode via Settings tab (no TopAppBar on AppShell)
      expect(find.byType(TopAppBar), findsNothing);
      await tester.tap(find.byIcon(Icons.settings_outlined).last);
      await tester.pumpAndSettle();
      final darkBtn = find.byKey(const ValueKey('theme-option-dark'));
      await tester.ensureVisible(darkBtn);
      await tester.tap(darkBtn);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );

      // Open frosted glass More sheet in Dark mode
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(MobileMoreSheet), findsOneWidget);
    },
  );

  testWidgets(
    'iOS platform uses Cupertino back navigation, bouncing scroll physics, and CupertinoAlertDialog on sign out',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pumpAndSettle();

      // Open Analytics sub-page on iOS via More sheet -> uses Cupertino back icon
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.byIcon(Icons.bar_chart_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Pop Analytics back to AppShell and switch to Settings tab
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Scrollable on iOS uses BouncingScrollPhysics
      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).last,
      );
      expect(scrollable.physics, isA<BouncingScrollPhysics>());

      // Trigger Sign Out -> CupertinoAlertDialog appears; Cancel keeps session
      final logoutButton = find.byIcon(Icons.logout_rounded).last;
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);

      await tester.tap(find.text('Болдырмау'));
      await tester.pumpAndSettle();
      expect(authedProvider.isAuthenticated, isTrue);

      // Confirm sign out returns to AuthScreen
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Шығу').last);
      await tester.pumpAndSettle();
      expect(authedProvider.isAuthenticated, isFalse);
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen 3-way theme selector switches System, Light, and Dark modes',
    (tester) async {
      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          themeProvider: themeProvider,
          initialRoute: AppRoutes.settings,
        ),
      );
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.system);

      final darkBtn = find.byKey(const ValueKey('theme-option-dark'));
      await tester.ensureVisible(darkBtn);
      await tester.tap(darkBtn);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.dark);

      final lightBtn = find.byKey(const ValueKey('theme-option-light'));
      await tester.ensureVisible(lightBtn);
      await tester.tap(lightBtn);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.light);

      final systemBtn = find.byKey(const ValueKey('theme-option-system'));
      await tester.ensureVisible(systemBtn);
      await tester.tap(systemBtn);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.system);
    },
  );

  testWidgets(
    'TimerProvider counts down across navigation and TaskFormModal opens from FAB',
    (tester) async {
      final timerProvider = TimerProvider();
      addTearDown(timerProvider.dispose);
      expect(timerProvider.formattedTime, '25:00');
      timerProvider.toggleStartPause();
      expect(timerProvider.isRunning, isTrue);

      await tester.pump(const Duration(seconds: 2));
      expect(timerProvider.secondsLeft, 1498);
      expect(timerProvider.formattedTime, '24:58');

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          timerProvider: timerProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Primary AppShell has no TopAppBar; open TimerScreen via More sheet & verify live countdown
      expect(find.byType(TopAppBar), findsNothing);
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.byIcon(Icons.timer_outlined),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(TimerScreen), findsOneWidget);
      expect(find.textContaining('24:'), findsOneWidget);

      timerProvider.reset();
      expect(timerProvider.isRunning, isFalse);
      expect(timerProvider.formattedTime, '25:00');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Tapping FAB opens adaptive TaskFormModal
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TaskFormModal), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen haptics toggle, display name editor, Timer duration stepper, and Dashboard completion banner work seamlessly',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );
      final taskProvider = TaskProvider(
        taskService: _FakeTaskService([
          TaskModel(
            id: 'done-1',
            weekId: 'w1',
            userId: 'user-123',
            dayOfWeek: DateTime.now().weekday,
            title: 'Completed task',
            status: 'done',
          ),
        ]),
        weekService: _FakeWeekService(),
      );
      final timerProvider = TimerProvider();
      addTearDown(timerProvider.dispose);

      // 1) Dashboard shows day completion banner and Hero tap opens Analytics
      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          taskProvider: taskProvider,
          timerProvider: timerProvider,
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Бүгінгі барлық тапсырма орындалды!'),
        findsOneWidget,
      );

      await tester.tap(find.textContaining('АПТА ПРОГРЕСІ'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsWidgets);

      // Pop AnalyticsScreen back to AppShell, then switch to Settings tab
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // 2) Open Settings: toggle Haptics & update display name
      await tester.tap(find.byIcon(Icons.settings_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      final hapticsSwitch = find.byKey(const ValueKey('settings-haptics-switch'));
      await tester.ensureVisible(hapticsSwitch);
      await tester.tap(hapticsSwitch);
      await tester.pumpAndSettle();
      expect(PlatformAdaptive.hapticsEnabled, isFalse);

      final editNameBtn = find.byKey(const ValueKey('settings-edit-name'));
      await tester.ensureVisible(editNameBtn);
      await tester.tap(editNameBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Nurlan');
      await tester.tap(find.text('Сақтау'));
      await tester.pumpAndSettle();
      expect(authProvider.user?.userMetadata?['display_name'], 'Nurlan');
      expect(find.text('Nurlan'), findsOneWidget);

      // 3) Open More sheet directly from Settings tab & test Timer -5 / +5 duration adjusters
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.byIcon(Icons.timer_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TimerScreen), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);

      final minus5 = find.byKey(const ValueKey('timer-minus-5'));
      await tester.ensureVisible(minus5);
      await tester.tap(minus5);
      await tester.pumpAndSettle();
      expect(find.text('20:00'), findsOneWidget);

      final plus5 = find.byKey(const ValueKey('timer-plus-5'));
      await tester.ensureVisible(plus5);
      await tester.tap(plus5);
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
    },
  );

  test('Classic iOS color palette and cached ThemeData optimization are preserved', () {
    final light1 = AppTheme.light();
    final light2 = AppTheme.light();
    final dark1 = AppTheme.dark();
    final dark2 = AppTheme.dark();

    expect(identical(light1, light2), isTrue);
    expect(identical(dark1, dark2), isTrue);
    expect(light1.colorScheme.primary, const Color(0xFF007AFF));
    expect(dark1.colorScheme.primary, const Color(0xFF0A84FF));
  });

  testWidgets(
    'AnimatedBottomNavBar Liquid Glass supports interactive horizontal drag scrubbing across tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authedProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authedProvider,
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = find.byType(AnimatedBottomNavBar);
      expect(navBar, findsOneWidget);
      final navRect = tester.getRect(navBar);

      // Drag from slot 0 (Home) to slot 2 (AI Assistant, middle of capsule)
      final startPoint = Offset(navRect.left + navRect.width * 0.12, navRect.center.dy);
      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(Offset(navRect.center.dx, navRect.center.dy));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('AI Көмекші'), findsWidgets);
    },
  );

  testWidgets(
    'TaskDetailModal replaces inline edit/delete icons and enforces confirmation on edit and delete',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );
      final fakeTaskService = _FakeTaskService([
        TaskModel(
          id: 't-view-1',
          weekId: 'w1',
          userId: 'user-123',
          dayOfWeek: DateTime.now().weekday,
          title: 'Draft Spec',
          description: 'Detailed notes',
          category: 'Жоба',
          priority: 'high',
          dueTime: '14:30',
        ),
      ]);
      final taskProvider = TaskProvider(
        taskService: fakeTaskService,
        weekService: _FakeWeekService(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          taskProvider: taskProvider,
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll task card clear of bottom-right FAB, then open Task View modal
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-view-t-view-1')));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailModal), findsOneWidget);
      expect(find.text('Draft Spec'), findsWidgets);
      expect(find.text('Detailed notes'), findsOneWidget);
      expect(find.byKey(const ValueKey('task-detail-delete')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-detail-edit')), findsOneWidget);

      // Edit flow requires confirmation dialog before saving
      await tester.tap(find.byKey(const ValueKey('task-detail-edit')));
      await tester.pumpAndSettle();
      expect(find.byType(TaskFormModal), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(TaskFormModal),
          matching: find.byType(TextField),
        ).first,
        'Updated Spec',
      );
      await tester.tap(find.text('Сақтау').last);
      await tester.pumpAndSettle();
      expect(find.text('Өзгерістерді сақтау'), findsOneWidget);

      // Cancel keeps task unedited
      await tester.tap(find.text('Болдырмау').last);
      await tester.pumpAndSettle();
      expect(fakeTaskService.updatedTaskCalls, isEmpty);

      // Save & Confirm applies edit
      await tester.tap(find.text('Сақтау').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeTaskService.updatedTaskCalls.length, 1);
      expect(fakeTaskService.updatedTaskCalls.first['title'], 'Updated Spec');
      expect(find.text('Updated Spec'), findsOneWidget);

      // Re-open View modal -> Delete flow requires confirmation dialog
      await tester.tap(find.byKey(const ValueKey('task-view-t-view-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-detail-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Жоспарды жою'), findsOneWidget);

      // Cancel keeps task
      await tester.tap(find.text('Болдырмау').last);
      await tester.pumpAndSettle();
      expect(fakeTaskService.deletedTaskIds, isEmpty);

      // Confirm removes task
      await tester.tap(find.byKey(const ValueKey('task-detail-delete')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeTaskService.deletedTaskIds, ['t-view-1']);
      expect(find.text('Updated Spec'), findsNothing);
    },
  );

  testWidgets(
    'ArchiveScreen excludes weeks without tasks and AppNavConfig enforces exact tab and More ordering',
    (tester) async {
      expect(
        AppNavConfig.primaryItems.map((e) => e.route).toList(),
        [
          AppRoutes.home,
          AppRoutes.week,
          AppRoutes.assistant,
          AppRoutes.settings,
        ],
      );
      expect(
        AppNavConfig.secondaryItems.map((e) => e.route).toList(),
        [
          AppRoutes.timer,
          AppRoutes.analytics,
          AppRoutes.weeklyReview,
          AppRoutes.archive,
          AppRoutes.admin,
        ],
      );

      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      // Verify More sheet renders Timer -> Analytics -> Review -> Archive top-to-bottom
      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      // Verify More sheet renders 3-column grid on 390px viewport in order:
      // Row 1: Timer -> Analytics -> Review; Row 2: Archive
      final timerPos = tester.getCenter(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.text('Таймер'),
        ),
      );
      final analyticsPos = tester.getCenter(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.text('Аналитика'),
        ),
      );
      final reviewPos = tester.getCenter(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.text('Қорытынды'),
        ),
      );
      final archivePos = tester.getCenter(
        find.descendant(
          of: find.byType(MobileMoreSheet),
          matching: find.text('Мұрағат'),
        ),
      );

      expect(timerPos.dx, lessThan(analyticsPos.dx));
      expect(analyticsPos.dx, lessThan(reviewPos.dx));
      expect(reviewPos.dy, lessThan(archivePos.dy));

      // Verify ArchiveScreen excludes weeks with 0 tasks
      final fakeWeeks = _FakeWeekService(
        weeksOverride: [
          WeekModel(
            id: 'w-filled',
            userId: 'user-123',
            weekStartDate: '2026-11-02',
            quote: '',
          ),
          WeekModel(
            id: 'w-empty',
            userId: 'user-123',
            weekStartDate: '2026-10-26',
            quote: '',
          ),
        ],
      );
      final fakeTasks = _FakeTaskService(
        const [],
        {
          'w-filled': [
            TaskModel(
              id: 't-arch-1',
              weekId: 'w-filled',
              userId: 'user-123',
              dayOfWeek: 1,
              title: 'Archived Task',
              status: 'done',
            ),
          ],
          'w-empty': const [],
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          key: const ValueKey('archive-test-root'),
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(
              create: (_) => TaskProvider(
                taskService: fakeTasks,
                weekService: fakeWeeks,
              ),
            ),
            ChangeNotifierProvider(create: (_) => TimerProvider()),
            ChangeNotifierProvider(create: (_) => MusicProvider()),
          ],
          child: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: ArchiveScreen(
                weekService: fakeWeeks,
                taskService: fakeTasks,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Non-empty week (2026-11-02) is shown; empty week (2026-10-26) is filtered out
      final filledLabel = WeekUtils.formatWeekRange('2026-11-02', 'kk');
      final emptyLabel = WeekUtils.formatWeekRange('2026-10-26', 'kk');
      expect(find.text(filledLabel), findsOneWidget);
      expect(find.text(emptyLabel), findsNothing);
    },
  );

  test('GamificationProvider awards XP, calculates level and streak badges on task completion', () async {
    final gamification = GamificationProvider();
    expect(gamification.level, 1);
    expect(gamification.xp, 0);

    final task = TaskModel(
      id: 'task-gamify-1',
      weekId: 'w1',
      userId: 'user-123',
      dayOfWeek: 1,
      title: 'Complete important feature',
      priority: 'high',
    );

    // Toggle task done -> +40 XP for high priority + first_step badge
    await gamification.onTaskToggled(
      task: task,
      isNowDone: true,
      allDayTasksDone: false,
    );

    expect(gamification.xp, 40);
    expect(gamification.totalTasksDone, 1);
    expect(gamification.unlockedBadgeIds.contains('first_step'), isTrue);
    expect(gamification.currentCelebration, isNotNull);

    // Complete all daily tasks -> bonus XP and level up!
    await gamification.onTaskToggled(
      task: task,
      isNowDone: true,
      allDayTasksDone: true,
    );

    expect(gamification.xp, greaterThanOrEqualTo(100));
    expect(gamification.level, greaterThanOrEqualTo(2));
    expect(gamification.unlockedBadgeIds.contains('daily_clear'), isTrue);

    // Test streak badges
    await gamification.checkStreakBadges(7);
    expect(gamification.unlockedBadgeIds.contains('streak_3'), isTrue);
    expect(gamification.unlockedBadgeIds.contains('streak_7'), isTrue);
  });

  testWidgets(
    'WidgetDataService synchronizes today snapshot and Settings renders Achievements and Reminders cards',
    (tester) async {
      final user = User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Ayan'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'ayan@example.com',
      );
      final session = Session(
        accessToken: 'token-abc',
        tokenType: 'bearer',
        user: user,
      );
      final authProvider = AuthProvider(
        authService: _FakeAuthService(initialSession: session),
      );

      // Verify WidgetDataService snapshot serialization
      await WidgetDataService.syncWidgetData(
        dateFormatted: '13.11',
        todayTasks: [
          TaskModel(
            id: 't-w-1',
            weekId: 'w1',
            userId: 'user-123',
            dayOfWeek: 1,
            title: 'Test Widget Task',
            dueTime: '14:00',
            status: 'done',
          ),
          TaskModel(
            id: 't-w-2',
            weekId: 'w1',
            userId: 'user-123',
            dayOfWeek: 1,
            title: 'Second Task',
            status: 'todo',
          ),
        ],
        streak: 5,
      );

      final snapshot = await WidgetDataService.getWidgetSnapshot();
      expect(snapshot['date'], '13.11');
      expect(snapshot['streak'], 5);
      expect(snapshot['total'], 2);
      expect(snapshot['done'], 1);
      expect(snapshot['pct'], 50);

      // Open Settings and verify Achievements and Reminders cards are visible
      await tester.pumpWidget(
        _buildTestApp(
          authProvider: authProvider,
          viewport: const Size(390, 844),
          initialRoute: AppRoutes.settings,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Жетістіктер мен Деңгей'), findsOneWidget);
      expect(find.text('Еске салулар'), findsOneWidget);
      expect(find.text('Экран виджеттері'), findsOneWidget);
    },
  );
}
