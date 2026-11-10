import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../state/ai_chat_provider.dart';
import '../../../state/task_provider.dart';
import 'widgets/plan_review_dialog.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

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
    if (text.trim().isEmpty) return;

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final chatProvider = Provider.of<AiChatProvider>(context, listen: false);

    _inputController.clear();
    _scrollToBottom();

    await chatProvider.sendMessage(
      text: text,
      weekStartDate: taskProvider.weekStartDate,
      quote: taskProvider.currentWeek?.quote ?? '',
      tasks: taskProvider.tasks,
      uiLang: lang.currentLocale,
      errorPrefix: lang.t('auth.error'),
    );
    if (mounted) _scrollToBottom();
  }

  Future<void> _extractAndReviewPlan(String content) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final chatProvider = Provider.of<AiChatProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(lang.t('common.loading')),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final tasks = await chatProvider.extractPlan(
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(lang.t('common.empty')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('${lang.t('auth.error')}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final chat = Provider.of<AiChatProvider>(context);
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
      ...chat.messages,
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
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
                      if (chat.messages.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                          tooltip: lang.t('assistant.clearChat'),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          onPressed: () async {
                            PlatformAdaptive.hapticLight();
                            final confirmed = await showAdaptiveConfirmDialog(
                              context,
                              title: lang.t('assistant.clearChat'),
                              body: lang.t('assistant.clearConfirm'),
                              confirmLabel: lang.t('common.delete'),
                              cancelLabel: lang.t('common.cancel'),
                              destructive: true,
                            );
                            if (confirmed) {
                              chat.clearMessages();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: PlatformAdaptive.scrollPhysics(context),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  if (!isUser) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (hasPlanKeywords)
                                          OutlinedButton(
                                            onPressed: () =>
                                                _extractAndReviewPlan(content),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(44, 44),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.calendar_month,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    lang.t(
                                                      'assistant.extractPlan',
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.copy_rounded,
                                            size: 17,
                                            color: isDark
                                                ? AppColors.darkSecondaryText
                                                : AppColors.lightSecondaryText,
                                          ),
                                          tooltip: 'Copy',
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          onPressed: () async {
                                            PlatformAdaptive.hapticSelection();
                                            await Clipboard.setData(
                                              ClipboardData(text: content),
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                SnackBar(
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                  content: Text(
                                                    lang.t('assistant.copied'),
                                                  ),
                                                ),
                                              );
                                          },
                                        ),
                                      ],
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

              if (chat.isSending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AdaptiveLoadingIndicator(radius: 9),
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
                                  ? [AppColors.darkPrimary, AppColors.indigo]
                                  : [AppColors.lightPrimary, AppColors.teal],
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
