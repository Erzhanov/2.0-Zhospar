import 'package:flutter/material.dart';
import '../data/models/task.dart';
import '../data/services/ai_service.dart';

/// Persistent AI chat state across tab switches, cleared cleanly on sign-out.
class AiChatProvider extends ChangeNotifier {
  final AiService _aiService;
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  String? _activeUserId;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  AiChatProvider({AiService? aiService}) : _aiService = aiService ?? AiService();

  void syncAuthUser(String? userId) {
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    if (userId == null) {
      _messages.clear();
      _isSending = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    if (_messages.isEmpty) return;
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    required String weekStartDate,
    required String quote,
    required List<TaskModel> tasks,
    required String uiLang,
    required String errorPrefix,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _messages.add({'role': 'user', 'content': trimmed});
    _isSending = true;
    notifyListeners();

    final buffer = StringBuffer();
    buffer.writeln('Week ($weekStartDate):');
    if (quote.isNotEmpty) {
      buffer.writeln('Quote: $quote');
    }
    for (final t in tasks) {
      buffer.writeln('  [Day ${t.dayOfWeek}] ${t.title} (${t.priority})');
    }

    try {
      final reply = await _aiService.sendChatMessage(
        messages: _messages,
        planContext: buffer.toString(),
        uiLang: uiLang,
      );
      _messages.add({'role': 'assistant', 'content': reply});
    } catch (e) {
      _messages.add({'role': 'assistant', 'content': '$errorPrefix: $e'});
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> extractPlan({
    required String planText,
    required String uiLang,
  }) {
    return _aiService.extractPlan(planText: planText, uiLang: uiLang);
  }
}
