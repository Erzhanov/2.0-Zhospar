import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ai_service.dart';
import '../../providers/task_provider.dart';
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

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Сәлем! Мен сіздің апталық жоспарыңызды құруға және реттеуге көмектесетін AI көмекшіңізбін. Қандай мақсаттарыңыз бар немесе қай күндерге тапсырмалар қойғыңыз келеді?',
    }
  ];
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
    if (text.trim().isEmpty) return;

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Prepare plan context
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

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Қате орын алды: $e. Қайта көріңіз.',
        });
      });
      _scrollToBottom();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _extractAndReviewPlan(String content) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жоспар талдануда...'),
        duration: Duration(seconds: 1),
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
          const SnackBar(content: Text('Нақты жоспар табылмады.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = [
      '📚 Оқу жоспарын құру',
      '🗓️ Бүгінгі күн кестесі',
      '💪 Мотивация берші',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.purple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('assistant.title'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        lang.t('assistant.subtitle'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  final isUser = msg['role'] == 'user';
                  final content = msg['content'] as String;

                  // Check if message might contain plan tasks
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
                      mainAxisAlignment:
                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.purple, size: 16),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isUser ? 18 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 18),
                              ),
                              border: Border.all(
                                color: isUser
                                    ? Colors.transparent
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: isUser
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (hasPlanKeywords) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => _extractAndReviewPlan(content),
                                    icon: const Icon(Icons.calendar_month, size: 15),
                                    label: Text(
                                      lang.t('assistant.extractPlan'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
                      'AI жауап дайындауда...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: chips.map((c) {
                  return GestureDetector(
                    onTap: () => _sendMessage(c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: lang.t('assistant.hint'),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    onPressed: () => _sendMessage(_inputController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
