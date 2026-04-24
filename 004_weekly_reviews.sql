-- 004_weekly_reviews.sql
-- Tabela para registro do histórico de Revisões Semanais GTD

CREATE TABLE IF NOT EXISTS public.weekly_reviews (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workspace_id uuid, -- Para compatibilidade futura com workspaces da equipe
  started_at timestamptz NOT NULL,
  completed_at timestamptz,
  inbox_processed_count int DEFAULT 0,
  tasks_reviewed_count int DEFAULT 0,
  projects_reviewed_count int DEFAULT 0,
  weekly_focus text,
  created_at timestamptz DEFAULT now()
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_weekly_reviews_user ON public.weekly_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_reviews_created ON public.weekly_reviews(created_at DESC);

-- Habilitar RLS
ALTER TABLE public.weekly_reviews ENABLE ROW LEVEL SECURITY;

-- Nova Policy: usuário só pode ver/inserir suas próprias revisões
CREATE POLICY "weekly_reviews_own" ON public.weekly_reviews
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
