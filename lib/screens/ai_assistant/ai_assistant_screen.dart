import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/common/glass_surface.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/plan_review_dialog.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _aiService = AiService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final buffer = StringBuffer();
    buffer.writeln('Апта (басталуы ${taskProvider.weekStartDate}):');
    if (taskProvider.currentWeek?.quote.isNotEmpty == true) {
      buffer.writeln('Дәйексөз: ${taskProvider.currentWeek!.quote}');
    }
    for (final t in taskProvider.tasks) {
      buffer.writeln('  [Күн ${t.dayOfWeek}] ${t.title} (${t.priority})');
    }

    try {
      final reply = await _aiService.sendChatMessage(
        messages: _messages,
        planContext: buffer.toString(),
        uiLang: lang.currentLocale,
      );

      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '${lang.t('auth.error')}: $e',
        });
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _extractAndReviewPlan(String content) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.t('common.loading')),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final tasks = await _aiService.extractPlan(
        planText: content,
        uiLang: lang.currentLocale,
      );

      if (tasks.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (_) => PlanReviewDialog(initialTasks: tasks),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('common.empty'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.t('auth.error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accent = isDark ? AppColors.darkPrimaryBright : primary;

    final chips = [
      lang.t('assistant.chipStudy'),
      lang.t('assistant.chipToday'),
      lang.t('assistant.chipMotivation'),
    ];
    final displayMessages = [
      {'role': 'assistant', 'content': lang.t('assistant.welcome')},
      ..._messages,
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Floating Assistant Header Card (no harsh divider)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: GlassSurface(
                  borderRadius: 22,
                  glowColor: AppColors.purple,
                  elevation: 0.7,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.purple,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('assistant.title'),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              lang.t('assistant.subtitle'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Weightless Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, i) {
                    final msg = displayMessages[i];
                    final isUser = msg['role'] == 'user';
                    final content = msg['content'] as String;

                    final hasPlanKeywords = !isUser &&
                        (content.contains('Дүйсенбі') ||
                            content.contains('Понедельник') ||
                            content.contains('Monday') ||
                            content.contains('жоспар') ||
                            content.contains('кесте') ||
                            content.contains('1.') ||
                            content.contains('•'));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.purple.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: AppColors.purple,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: GlassSurface(
                              borderRadius: 22,
                              elevation: 0.7,
                              glowColor: isUser ? accent : AppColors.purple,
                              tintColor: isUser ? primary : null,
                              borderColor: isUser
                                  ? Colors.white.withValues(alpha: 0.28)
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    content,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.48,
                                      color: isUser
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkForeground
                                              : AppColors.lightForeground),
                                    ),
                                  ),
                                  if (hasPlanKeywords) ...[
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _extractAndReviewPlan(content),
                                      icon: const Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                      ),
                                      label: Text(
                                        lang.t('assistant.extractPlan'),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(44, 44),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang.t('assistant.thinking'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

              // Floating Quick Chips
              SingleChildScrollView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: chips.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TapScale(
                        onTap: () => _sendMessage(c),
                        minHeight: 44,
                        borderRadius: BorderRadius.circular(18),
                        child: GlassSurface(
                          borderRadius: 18,
                          elevation: 0.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Floating Glass Composer Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: GlassSurface(
                  enableBlur: true,
                  borderRadius: 26,
                  elevation: 0.9,
                  glowColor: accent,
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          onSubmitted: _sendMessage,
                          decoration: InputDecoration(
                            hintText: lang.t('assistant.hint'),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TapScale(
                        onTap: () => _sendMessage(_inputController.text),
                        minWidth: 46,
                        minHeight: 46,
                        borderRadius: BorderRadius.circular(23),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [AppColors.darkPrimary, AppColors.glowTeal]
                                  : [
                                      AppColors.lightPrimary,
                                      const Color(0xFF14B8A6),
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
