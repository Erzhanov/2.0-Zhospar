import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../state/auth_provider.dart';
import '../shell/widgets/top_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  String? _error;
  int _usersCount = 0;
  int _weeksCount = 0;
  int _tasksCount = 0;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final client = Supabase.instance.client;
      final profilesData = await client
          .from('profiles')
          .select('user_id, display_name, theme, created_at')
          .order('created_at', ascending: false)
          .limit(30);
      final weeksData = await client.from('weeks').select('id');
      final tasksData = await client.from('tasks').select('id');

      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(profilesData as List);
      setState(() {
        _profiles = list;
        _usersCount = list.length;
        _weeksCount = (weeksData as List).length;
        _tasksCount = (tasksData as List).length;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final deniedMsg = switch (lang.currentLocale) {
      'ru' => 'Доступ открыт только для администраторов.',
      'en' => 'Access is restricted to administrators.',
      _ => 'Бұл бөлім тек әкімшілерге қолжетімді.',
    };
    final usersLabel = switch (lang.currentLocale) {
      'ru' => 'Пользователи',
      'en' => 'Users',
      _ => 'Қолданушылар',
    };
    final weeksLabel = switch (lang.currentLocale) {
      'ru' => 'Недели',
      'en' => 'Weeks',
      _ => 'Апталар',
    };
    final tasksLabel = switch (lang.currentLocale) {
      'ru' => 'Задачи',
      'en' => 'Tasks',
      _ => 'Тапсырмалар',
    };

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopAppBar(
          title: lang.t('nav.admin'),
          isSubPage: true,
        ),
        body: !auth.isAdmin
            ? Center(
                child: MobilePageContainer(
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 36,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          deniedMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : _isLoading
                ? Center(child: AdaptiveLoadingIndicator(color: primary))
                : RefreshIndicator.adaptive(
                    onRefresh: _loadStats,
                    child: SingleChildScrollView(
                      physics: PlatformAdaptive.scrollPhysics(context),
                      child: MobilePageContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              AppCard(
                                borderColor: AppColors.destructive
                                    .withValues(alpha: 0.4),
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.destructive,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    label: usersLabel,
                                    value: '$_usersCount',
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MetricCard(
                                    label: weeksLabel,
                                    value: '$_weeksCount',
                                    color: AppColors.glowIndigo,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MetricCard(
                                    label: tasksLabel,
                                    value: '$_tasksCount',
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              usersLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_profiles.isEmpty)
                              AppCard(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  lang.t('common.empty'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted),
                                ),
                              )
                            else
                              ..._profiles.map((p) {
                                final name = (p['display_name'] ?? 'User')
                                    .toString()
                                    .trim();
                                final uid = (p['user_id'] ?? '').toString();
                                final themeVal =
                                    (p['theme'] ?? 'system').toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SpringPopIn(
                                    child: AppCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                primary.withValues(alpha: 0.16),
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name.isEmpty ? 'User' : name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  uid,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primary.withValues(
                                                  alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              themeVal,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    return AppCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
