import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ai_agent_models.dart';
import '../../domain/services/ai_prompt_defaults.dart';
import '../../../auth/domain/data_providers.dart';

class AiPromptConfigRepository {
  final Ref _ref;
  AiPromptConfigRepository(this._ref);

  Future<List<AiAgentConfig>> getAgentConfigs(AiAgentType type) async {
    final defaults = AiPromptDefaults.getDefaultConfig(type);
    
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        final List<dynamic> data = await client
            .from('ai_agent_configs')
            .select()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name);
            
        final List<AiAgentConfig> configs = data.map((item) {
          return AiAgentConfig(
            agentType: type,
            name: item['name'] as String? ?? 'Padrão',
            systemInstruction: item['system_instruction'] as String? ?? '',
            businessRules: item['business_rules'] as String? ?? '',
            toneOfVoice: item['tone_of_voice'] as String? ?? '',
            avoidRules: item['avoid_rules'] as String? ?? '',
            examples: item['examples'] as String? ?? '',
          );
        }).toList();

        // Ensure at least the 'Padrão' prompt is in the list
        final hasDefault = configs.any((c) => c.name == 'Padrão');
        if (!hasDefault) {
          configs.insert(0, defaults.copyWith(name: 'Padrão'));
        }
        
        return configs;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error listing configs from Supabase for ${type.name}: $e');
    }
    
    return [defaults.copyWith(name: 'Padrão')];
  }

  Future<AiAgentConfig> getAgentConfig(AiAgentType type, {String name = 'Padrão'}) async {
    final defaults = AiPromptDefaults.getDefaultConfig(type).copyWith(name: name);
    
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        final data = await client
            .from('ai_agent_configs')
            .select()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name)
            .eq('name', name)
            .maybeSingle();
            
        if (data != null) {
          print('[AiPromptConfigRepository] Loaded config for ${type.name} ($name) from Supabase.');
          return AiAgentConfig(
            agentType: type,
            name: name,
            systemInstruction: data['system_instruction'] as String? ?? defaults.systemInstruction,
            businessRules: data['business_rules'] as String? ?? defaults.businessRules,
            toneOfVoice: data['tone_of_voice'] as String? ?? defaults.toneOfVoice,
            avoidRules: data['avoid_rules'] as String? ?? defaults.avoidRules,
            examples: data['examples'] as String? ?? defaults.examples,
          );
        }
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error loading config from Supabase for ${type.name} ($name): $e. Falling back to defaults.');
    }
    
    print('[AiPromptConfigRepository] Returning defaults for ${type.name} ($name)');
    return defaults;
  }

  Future<void> saveAgentConfig(AiAgentConfig config) async {
    final type = config.agentType;
    final name = config.name.trim();
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        print('[AiPromptConfigRepository] Saving config for ${type.name} ($name) to Supabase...');
        await client.from('ai_agent_configs').upsert({
          'workspace_id': workspace.id,
          'agent_type': type.name,
          'name': name,
          'system_instruction': config.systemInstruction.trim(),
          'business_rules': config.businessRules.trim(),
          'tone_of_voice': config.toneOfVoice.trim(),
          'avoid_rules': config.avoidRules.trim(),
          'examples': config.examples.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'workspace_id, agent_type, name');
        print('[AiPromptConfigRepository] Config for ${type.name} ($name) saved successfully.');
        return;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error saving config to Supabase for ${type.name} ($name): $e');
      rethrow;
    }
    
    throw Exception('Workspace não selecionado para salvar configurações.');
  }

  Future<void> resetAgentConfig(AiAgentType type, {String name = 'Padrão'}) async {
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        print('[AiPromptConfigRepository] Resetting config for ${type.name} ($name) in Supabase...');
        await client
            .from('ai_agent_configs')
            .delete()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name)
            .eq('name', name);
        print('[AiPromptConfigRepository] Config for ${type.name} ($name) reset successfully in Supabase.');
        return;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error resetting config in Supabase for ${type.name} ($name): $e');
      rethrow;
    }
    
    throw Exception('Workspace não selecionado para resetar configurações.');
  }

  Future<void> deleteAgentConfig(AiAgentType type, String name) async {
    if (name == 'Padrão') {
      throw Exception('Não é permitido excluir o prompt Padrão.');
    }
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        print('[AiPromptConfigRepository] Deleting config for ${type.name} ($name) in Supabase...');
        await client
            .from('ai_agent_configs')
            .delete()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name)
            .eq('name', name);
        print('[AiPromptConfigRepository] Config for ${type.name} ($name) deleted successfully in Supabase.');
        return;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error deleting config in Supabase for ${type.name} ($name): $e');
      rethrow;
    }
    
    throw Exception('Workspace não selecionado para excluir configurações.');
  }
}

final aiPromptConfigRepositoryProvider = Provider<AiPromptConfigRepository>((ref) {
  return AiPromptConfigRepository(ref);
});
