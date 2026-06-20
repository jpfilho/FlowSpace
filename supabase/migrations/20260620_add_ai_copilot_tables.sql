-- Migration: Add AI Copilot Tables, Indexes, and RLS policies
-- Date: 2026-06-20

-- ── 1. Create Tables ──────────────────────────────────────────

-- ai_recommendations
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id             UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  workspace_id        UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id             UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  recommendation_type TEXT NOT NULL, -- 'risk_alert' | 'priority_suggestion' | 'next_steps' | 'weekly_summary'
  recommendation_text TEXT NOT NULL,
  justification       TEXT NOT NULL,
  risk_level          TEXT NOT NULL DEFAULT 'low', -- 'low' | 'medium' | 'high' | 'critical'
  suggested_priority  TEXT NOT NULL DEFAULT 'medium', -- 'low' | 'medium' | 'high' | 'urgent' | 'critical'
  confidence_score    DECIMAL(3,2) DEFAULT 1.00,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  status              TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'accepted' | 'rejected' | 'adjusted'
  human_action        TEXT,
  human_feedback      TEXT, -- 'useful' | 'incorrect_risk' | 'missing_context'
  feedback_comment    TEXT
);

-- ai_task_analysis
CREATE TABLE IF NOT EXISTS public.ai_task_analysis (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id             UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE UNIQUE,
  workspace_id        UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  risk_level          TEXT NOT NULL DEFAULT 'low', -- 'low' | 'medium' | 'high' | 'critical'
  risk_reason         TEXT NOT NULL,
  missing_information TEXT,
  suggested_next_step TEXT,
  analyzed_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ai_audit_logs
CREATE TABLE IF NOT EXISTS public.ai_audit_logs (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id                UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  workspace_id           UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id                UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action_type            TEXT NOT NULL, -- 'view' | 'accept_recommendation' | 'reject_recommendation' | 'adjust_recommendation'
  previous_value         TEXT,
  new_value              TEXT,
  ai_recommendation_id   UUID REFERENCES public.ai_recommendations(id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Enable Row Level Security (RLS) ─────────────────────────

ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_task_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_audit_logs ENABLE ROW LEVEL SECURITY;

-- ── 3. Policies for Workspace Members ──────────────────────────

-- Helper function 'is_workspace_member' is defined in 002_rls_policies.sql.
-- We use it to enforce that only workspace members can access AI data for that workspace.

CREATE POLICY "ai_recommendations_select" ON public.ai_recommendations
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_recommendations_insert" ON public.ai_recommendations
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_recommendations_update" ON public.ai_recommendations
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_task_analysis_select" ON public.ai_task_analysis
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_task_analysis_insert" ON public.ai_task_analysis
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_task_analysis_update" ON public.ai_task_analysis
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_audit_logs_select" ON public.ai_audit_logs
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "ai_audit_logs_insert" ON public.ai_audit_logs
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

-- ── 4. Create Indexes ──────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_ai_rec_workspace ON public.ai_recommendations(workspace_id);
CREATE INDEX IF NOT EXISTS idx_ai_rec_task ON public.ai_recommendations(task_id);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_workspace ON public.ai_task_analysis(workspace_id);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_task ON public.ai_task_analysis(task_id);
CREATE INDEX IF NOT EXISTS idx_ai_audit_workspace ON public.ai_audit_logs(workspace_id);
