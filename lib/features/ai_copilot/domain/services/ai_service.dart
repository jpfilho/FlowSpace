import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/data_providers.dart';
import '../models/ai_copilot_models.dart';
import 'ai_prompt_builder.dart';

class AiService {
  static const String _prefsKey = 'gemini_api_key';
  static const String _modelPrefsKey = 'gemini_model_name';
  static const String _defaultModel = 'gemini-1.5-flash';

  /// Retrieves the API key, checking SharedPreferences first, then --dart-define environment
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final localKey = prefs.getString(_prefsKey);
    if (localKey != null && localKey.trim().isNotEmpty) {
      return localKey.trim();
    }
    // Fallback to Dart environment define
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    // No hardcoded fallback to avoid exposing secrets in source control
    return null;
  }

  /// Saves the API key to SharedPreferences
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  /// Clears the API key from SharedPreferences
  Future<void> deleteApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Retrieves the selected model name
  Future<String> getModelName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefsKey) ?? _defaultModel;
  }

  /// Saves the model name
  Future<void> saveModelName(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefsKey, modelName);
  }

  /// Calls the Gemini API with the given prompt and system instruction
  Future<Map<String, dynamic>> _callGeminiApi({
    required String prompt,
    required String systemInstruction,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API_KEY_MISSING: A chave da API do Gemini não foi configurada. Por favor, acesse as Configurações para adicioná-la.');
    }

    final model = await getModelName();
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        }
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? 'Erro desconhecido';
        throw Exception('Erro na API Gemini (${response.statusCode}): $errMsg');
      } catch (_) {
        throw Exception('Erro na API Gemini (${response.statusCode}): ${response.body}');
      }
    }

    final data = jsonDecode(response.body);
    final String? textResponse =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (textResponse == null || textResponse.trim().isEmpty) {
      throw Exception('Resposta vazia recebida do Gemini.');
    }

    // Sometimes Gemini wraps JSON in markdown ```json blocks even when told not to.
    String cleanJson = textResponse.trim();
    if (cleanJson.startsWith('```')) {
      final lines = cleanJson.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleanJson = lines.join('\n').trim();
    }

    return jsonDecode(cleanJson) as Map<String, dynamic>;
  }

  /// Evaluates a single task's risk, suggested priority, and next steps
  Future<Map<String, dynamic>> analyzeTask({
    required TaskData task,
    required List<Map<String, dynamic>> comments,
  }) async {
    final prompt = AiPromptBuilder.buildTaskAnalysisPrompt(
      task: task,
      comments: comments,
      now: DateTime.now(),
    );

    return await _callGeminiApi(
      prompt: prompt,
      systemInstruction: AiPromptBuilder.systemInstruction,
    );
  }

  /// Generates the Weekly Executive Report using all tasks
  Future<AiWeeklyReport> generateWeeklyReport({
    required List<TaskData> allTasks,
  }) async {
    final prompt = AiPromptBuilder.buildWeeklyReportPrompt(
      allTasks: allTasks,
      now: DateTime.now(),
    );

    final rawJson = await _callGeminiApi(
      prompt: prompt,
      systemInstruction: AiPromptBuilder.systemInstruction,
    );

    return AiWeeklyReport.fromJson(rawJson);
  }
}
