import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/data_providers.dart';
import '../models/ai_copilot_models.dart';
import '../models/ai_agent_models.dart';
import '../../data/repositories/ai_prompt_config_repository.dart';
import 'ai_prompt_builder.dart';

class AiService {
  final Ref _ref;
  AiService(this._ref);

  static const String _prefsKey = 'openai_api_key';
  static const String _modelPrefsKey = 'openai_model_name';
  static const String _defaultModel = 'gpt-4o-mini';

  /// Retrieves the API key, checking SharedPreferences first, then --dart-define environment
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final localKey = prefs.getString(_prefsKey);
    if (localKey != null && localKey.trim().isNotEmpty) {
      return localKey.trim();
    }
    // Fallback to Dart environment define
    const envKey = String.fromEnvironment('OPENAI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
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

  /// Calls the OpenAI API with the given prompt and system instruction
  Future<Map<String, dynamic>> _callOpenAiApi({
    required String prompt,
    required String systemInstruction,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API_KEY_MISSING: A chave da API do ChatGPT não foi configurada. Por favor, acesse as Configurações para adicioná-la.');
    }

    final model = await getModelName();
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          if (systemInstruction.isNotEmpty)
            {'role': 'system', 'content': systemInstruction},
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.1,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? 'Erro desconhecido';
        throw Exception('Erro na API OpenAI (${response.statusCode}): $errMsg');
      } catch (_) {
        throw Exception('Erro na API OpenAI (${response.statusCode}): ${response.body}');
      }
    }

    final data = jsonDecode(response.body);
    final String? textResponse = data['choices']?[0]?['message']?['content'] as String?;

    if (textResponse == null || textResponse.trim().isEmpty) {
      throw Exception('Resposta vazia recebida do ChatGPT.');
    }

    // OpenAI json_object format is already a clean JSON string, but we clean markdown formatting just in case
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
    final repo = _ref.read(aiPromptConfigRepositoryProvider);
    final config = await repo.getAgentConfig(AiAgentType.taskRiskAnalysis);

    final prompt = AiPromptBuilder.buildTaskAnalysisPrompt(
      task: task,
      comments: comments,
      now: DateTime.now(),
      config: config,
    );

    return await _callOpenAiApi(
      prompt: prompt,
      systemInstruction: config.systemInstruction,
    );
  }

  /// Generates the Weekly Executive Report using all tasks
  Future<AiWeeklyReport> generateWeeklyReport({
    required List<TaskData> allTasks,
  }) async {
    final repo = _ref.read(aiPromptConfigRepositoryProvider);
    final config = await repo.getAgentConfig(AiAgentType.weeklyExecutiveReport);

    final prompt = AiPromptBuilder.buildWeeklyReportPrompt(
      allTasks: allTasks,
      now: DateTime.now(),
      config: config,
    );

    final rawJson = await _callOpenAiApi(
      prompt: prompt,
      systemInstruction: config.systemInstruction,
    );

    return AiWeeklyReport.fromJson(rawJson);
  }
}
