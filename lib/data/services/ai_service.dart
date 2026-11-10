import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class AiService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _accessToken => _client.auth.currentSession?.accessToken;

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.anonKey,
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  /// Send chat message to AI assistant
  Future<String> sendChatMessage({
    required List<Map<String, dynamic>> messages,
    String? planContext,
    String uiLang = 'kk',
  }) async {
    final url = Uri.parse('${SupabaseConfig.url}/functions/v1/ai-assistant');
    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'messages': messages,
        'planContext': planContext ?? '',
        'uiLang': uiLang,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // In Deno edge function it might return response text directly or in choices
      if (data is Map && data.containsKey('reply')) {
        return data['reply'] as String;
      } else if (data is Map && data.containsKey('choices')) {
        final choices = data['choices'] as List;
        if (choices.isNotEmpty && choices[0]['message'] != null) {
          return choices[0]['message']['content'] ?? '';
        }
      } else if (data is String) {
        return data;
      }
      return jsonEncode(data);
    } else {
      throw Exception('AI Response Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Extract structured plan from AI text
  Future<List<Map<String, dynamic>>> extractPlan({
    required String planText,
    String? userTimeHint,
    String uiLang = 'kk',
  }) async {
    final url = Uri.parse('${SupabaseConfig.url}/functions/v1/extract-plan');
    final Map<String, dynamic> body = {
      'planText': planText,
      'uiLang': uiLang,
    };
    if (userTimeHint != null) {
      body['userTimeHint'] = userTimeHint;
    }

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data.containsKey('tasks')) {
        return List<Map<String, dynamic>>.from(data['tasks']);
      }
      return [];
    } else {
      throw Exception('Extract Plan Error: ${response.statusCode}');
    }
  }
}
