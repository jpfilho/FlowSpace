-- Migration: Add AI Agent Configs table
-- Date: 2026-06-21

CREATE TABLE IF NOT EXISTS public.ai_agent_configs (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id        UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  agent_type          TEXT NOT NULL,
  system_instruction  TEXT NOT NULL,
  business_rules      TEXT NOT NULL,
  tone_of_voice       TEXT NOT NULL,
  avoid_rules         TEXT NOT NULL,
  examples            TEXT NOT NULL,
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(workspace_id, agent_type)
);

-- ── Enable Row Level Security (RLS) ─────────────────────────
ALTER TABLE public.ai_agent_configs ENABLE ROW LEVEL SECURITY;

-- ── Policies for Workspace Members ──────────────────────────
CREATE POLICY "ai_agent_configs_select" ON public.ai_agent_configs
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_agent_configs_insert" ON public.ai_agent_configs
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_agent_configs_update" ON public.ai_agent_configs
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_agent_configs_delete" ON public.ai_agent_configs
  FOR DELETE USING (public.is_workspace_member(workspace_id));

-- ── Create Indexes ──────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_ai_agent_configs_workspace ON public.ai_agent_configs(workspace_id);
