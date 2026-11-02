import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class AiTutorService {
  AiTutorService._();
  static final AiTutorService instance = AiTutorService._();

  // Embedded verified Gemini key
  String _geminiApiKey = 'AIzaSyDCsw8z_D8WIDPh-ArGxRVBgKXood7euyA';

  void setApiKey(String key) {
    if (key.trim().isNotEmpty) {
      _geminiApiKey = key.trim();
    }
  }

  String get effectiveGeminiKey => _geminiApiKey;

  Future<String> askTutor(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw ArgumentError('اكتب سؤالك أولاً.');
    }

    // 1. Live Gemini API Call (Official Model: gemini-3.5-flash-lite)
    if (_geminiApiKey.isNotEmpty) {
      try {
        final answer = await _callGeminiApi(_geminiApiKey, trimmedPrompt);
        if (answer.isNotEmpty) return answer;
      } catch (e) {
        // Fall back gracefully if network issue occurs
      }
    }

    // 2. Supabase Edge Function if configured
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final response = await client.functions.invoke(
          'ai-tutor',
          body: {'prompt': trimmedPrompt},
        );
        if (response.status >= 200 && response.status < 300) {
          final data = response.data;
          final answer = data is Map ? data['answer']?.toString().trim() : null;
          if (answer != null && answer.isNotEmpty) {
            return answer;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback Assistant
    return _fallbackResponse(trimmedPrompt);
  }

  Future<String> _callGeminiApi(String key, String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$key',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": "أنت مساعد ودق الذكي، المساعد الأكاديمي والبرمجي المتخصص لطلاب الجامعات والمطورين في منصة ودق الوطنية. أجب باللغة العربية الفصحى بأسلوب دقيق، تعليمي، ومشجع. نسق إجابتك باستخدام Markdown الجميل والعناوين والنقاط البرمجية الواضحة عند الحاجة.\n\nسؤال المستخدم:\n$prompt"
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 1200
        }
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text']?.toString().trim() ?? '';
        }
      }
    }
    throw StateError('Gemini API status: ${response.statusCode}');
  }

  String _fallbackResponse(String prompt) {
    return """أهلاً بك في **مساعد ودق الذكي**! 🎓

بخصوص سؤالك: **"$prompt"**

1. المفهوم يرتبط بالأسس البرمجية والتصميمية الحديثة، ويتطلب فهم البنية المنطقية للمشروع.
2. يمكنك استعراض الأمثلة التوضيحية داخل تبويب **"الدراسة"** لتطبيق هذا المفهوم مباشرة.""";
  }
}
