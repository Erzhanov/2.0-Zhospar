import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/navigation/top_app_bar.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: TopAppBar(
          title: lang.t('nav.admin'),
          isSubPage: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 52,
                  color: AppColors.destructive,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Бұл бетке тек әкімшілер кіре алады',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(lang.t('nav.back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final metrics = [
      _AdminMetric(
        'Жүйе күйі',
        'Белсенді',
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      _AdminMetric(
        'Нұсқасы',
        'v2.0.0',
        Icons.verified_rounded,
        AppColors.lightPrimary,
      ),
      _AdminMetric(
        'Supabase',
        'Байланысты',
        Icons.cloud_done_rounded,
        AppColors.teal,
      ),
      _AdminMetric(
        'AI Қызметі',
        'Қосулы',
        Icons.auto_awesome,
        AppColors.purple,
      ),
    ];

    return Scaffold(
      appBar: TopAppBar(
        title: lang.t('nav.admin'),
        isSubPage: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: MobilePageContainer(
            bottomClearance: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 340 ? 1 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 110,
                      ),
                      itemBuilder: (_, i) => _metricTile(metrics[i], isDark),
                    );
                  },
                ),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Жүйелік ақпарат',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ZHOSPAR 2.0 қосымшасының барлық мүмкіндіктері жұмыс істеп тұр. Деректер нақты уақытта Supabase бұлтында сақталады.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricTile(_AdminMetric metric, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(metric.icon, size: 22, color: metric.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminMetric(this.label, this.value, this.icon, this.color);
}
