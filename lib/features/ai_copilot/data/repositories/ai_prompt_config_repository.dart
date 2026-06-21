import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ai_agent_models.dart';
import '../../domain/services/ai_prompt_defaults.dart';
import '../../../auth/domain/data_providers.dart';

class AiPromptConfigRepository {
  final Ref _ref;
  AiPromptConfigRepository(this._ref);

  Future<AiAgentConfig> getAgentConfig(AiAgentType type) async {
    final defaults = AiPromptDefaults.getDefaultConfig(type);
    
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        final data = await client
            .from('ai_agent_configs')
            .select()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name)
            .maybeSingle();
            
        if (data != null) {
          print('[AiPromptConfigRepository] Loaded config for ${type.name} from Supabase:');
          return AiAgentConfig(
            agentType: type,
            systemInstruction: data['system_instruction'] as String? ?? defaults.systemInstruction,
            businessRules: data['business_rules'] as String? ?? defaults.businessRules,
            toneOfVoice: data['tone_of_voice'] as String? ?? defaults.toneOfVoice,
            avoidRules: data['avoid_rules'] as String? ?? defaults.avoidRules,
            examples: data['examples'] as String? ?? defaults.examples,
          );
        }
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error loading config from Supabase for ${type.name}: $e. Falling back to defaults.');
    }
    
    print('[AiPromptConfigRepository] Returning defaults for ${type.name}');
    return defaults;
  }

  Future<void> saveAgentConfig(AiAgentConfig config) async {
    final type = config.agentType;
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        print('[AiPromptConfigRepository] Saving config for ${type.name} to Supabase...');
        await client.from('ai_agent_configs').upsert({
          'workspace_id': workspace.id,
          'agent_type': type.name,
          'system_instruction': config.systemInstruction.trim(),
          'business_rules': config.businessRules.trim(),
          'tone_of_voice': config.toneOfVoice.trim(),
          'avoid_rules': config.avoidRules.trim(),
          'examples': config.examples.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'workspace_id, agent_type');
        print('[AiPromptConfigRepository] Config for ${type.name} saved to Supabase successfully.');
        return;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error saving config to Supabase for ${type.name}: $e');
      rethrow;
    }
    
    throw Exception('Workspace não selecionado para salvar configurações.');
  }

  Future<void> resetAgentConfig(AiAgentType type) async {
    try {
      final client = _ref.read(supabaseProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);
      
      if (workspace != null) {
        print('[AiPromptConfigRepository] Resetting config for ${type.name} in Supabase...');
        await client
            .from('ai_agent_configs')
            .delete()
            .eq('workspace_id', workspace.id)
            .eq('agent_type', type.name);
        print('[AiPromptConfigRepository] Config for ${type.name} reset successfully in Supabase.');
        return;
      }
    } catch (e) {
      print('[AiPromptConfigRepository] Error resetting config in Supabase for ${type.name}: $e');
      rethrow;
    }
    
    throw Exception('Workspace não selecionado para resetar configurações.');
  }
}

final aiPromptConfigRepositoryProvider = Provider<AiPromptConfigRepository>((ref) {
  return AiPromptConfigRepository(ref);
});
