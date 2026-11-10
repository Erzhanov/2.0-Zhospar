import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhospar_app/core/i18n/language_provider.dart';
import 'package:zhospar_app/core/routing/app_router.dart';
import 'package:zhospar_app/core/routing/app_routes.dart';
import 'package:zhospar_app/core/theme/app_theme.dart';
import 'package:zhospar_app/models/daily_reflection.dart';
import 'package:zhospar_app/models/task.dart';
import 'package:zhospar_app/models/week.dart';
import 'package:zhospar_app/models/weekly_review.dart';
import 'package:zhospar_app/providers/auth_provider.dart';
import 'package:zhospar_app/providers/music_provider.dart';
import 'package:zhospar_app/providers/task_provider.dart';
import 'package:zhospar_app/providers/theme_provider.dart';
import 'package:zhospar_app/screens/app_shell.dart';
import 'package:zhospar_app/screens/auth/auth_screen.dart';
import 'package:zhospar_app/screens/dashboard/dashboard_screen.dart';
import 'package:zhospar_app/screens/landing/landing_screen.dart';
import 'package:zhospar_app/screens/settings/settings_screen.dart';
import 'package:zhospar_app/screens/timer/timer_screen.dart';
import 'package:zhospar_app/services/auth_service.dart';
import 'package:zhospar_app/services/task_service.dart';
import 'package:zhospar_app/services/week_service.dart';
import 'package:zhospar_app/widgets/navigation/animated_bottom_nav_bar.dart';
import 'package:zhospar_app/widgets/task_item_widget.dart';

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
}

class _FakeWeekService implements WeekService {
  @override
  Future<List<WeekModel>> getAllWeeks() async => [
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

  _FakeTaskService([this.seedTasks = const []]);

  @override
  Future<TaskModel?> addTask({
    required String weekId,
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    String priority = 'med',
    String? dueTime,
  }) async =>
      TaskModel(
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

  @override
  Future<int> copyIncompleteTasks(
    String currentWeekId,
    String currentWeekStartDate,
  ) async =>
      0;

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<List<TaskModel>> getTasksForWeek(String weekId) async =>
      List.of(seedTasks);

  @override
  Future<Map<String, List<TaskModel>>> getTasksForWeeks(
    List<String> weekIds,
  ) async =>
      {for (final id in weekIds) id: List.of(seedTasks)};

  @override
  Future<int> replaceTasksForWeek(
    String weekId,
    List<Map<String, dynamic>> tasks,
  ) async =>
      tasks.length;

  @override
  Future<void> updateTask(String id, Map<String, dynamic> updates) async {}
}

Widget _buildTestApp({
  required AuthProvider authProvider,
  TaskProvider? taskProvider,
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

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
        create: (_) => tProvider,
        update: (_, auth, prev) {
          final p = prev ?? tProvider;
          p.syncAuthUser(auth.isAuthenticated ? auth.user?.id : null);
          return p;
        },
      ),
      ChangeNotifierProvider(create: (_) => MusicProvider()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: viewport),
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
      await tester.tap(find.byType(ElevatedButton).first);
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

      expect(find.byType(AppShell), findsOneWidget);

      // Open Settings via TopAppBar action icon
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
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

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);

      // Open More sheet -> navigate to TimerScreen
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.timer_outlined));
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

      // Verify bottom nav bar height >= 44px and task action icons >= 44x44px
      final navSize = tester.getSize(find.byType(AnimatedBottomNavBar));
      expect(navSize.height, greaterThanOrEqualTo(44));

      final taskEditButton = find.descendant(
        of: find.byType(TaskItemWidget),
        matching: find.ancestor(
          of: find.byIcon(Icons.edit_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(tester.getSize(taskEditButton.first).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(taskEditButton.first).height, greaterThanOrEqualTo(44));

      final taskDeleteButton = find.descendant(
        of: find.byType(TaskItemWidget),
        matching: find.ancestor(
          of: find.byIcon(Icons.delete_outline_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(
        tester.getSize(taskDeleteButton.first).width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(taskDeleteButton.first).height,
        greaterThanOrEqualTo(44),
      );

      // Tap Week Plan tab and verify Day/Week toggle works on 360px screen
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Апталық Жоспар'), findsOneWidget);

      // Tap Analytics tab
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Аналитика'), findsWidgets);

      // Tap AI Assistant tab
      await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
      await tester.pumpAndSettle();
      expect(find.text('AI Көмекші'), findsWidgets);

      // Open Settings via TopAppBar and verify sign-out returns to AuthScreen
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      final logoutButton = find.byIcon(Icons.logout_rounded).last;
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
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
}
