-- Migration: Add name column to AI Agent Configs table
-- Date: 2026-06-21

ALTER TABLE public.ai_agent_configs ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT 'Padrão';

-- Drop the old UNIQUE constraint on (workspace_id, agent_type)
ALTER TABLE public.ai_agent_configs DROP CONSTRAINT IF EXISTS ai_agent_configs_workspace_id_agent_type_key;

-- Add new UNIQUE constraint on (workspace_id, agent_type, name)
ALTER TABLE public.ai_agent_configs ADD CONSTRAINT ai_agent_configs_workspace_id_agent_type_name_key UNIQUE (workspace_id, agent_type, name);

-- Reload schema
NOTIFY pgrst, 'reload schema';
