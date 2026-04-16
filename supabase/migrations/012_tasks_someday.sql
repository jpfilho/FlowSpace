-- ============================================================
-- FlowSpace -- Adiciona campo is_someday na tabela tasks (012)
-- ============================================================
-- O GTD "Algum dia / Talvez" agrupa tarefas sem prazo definido
-- que podem ser feitas num futuro indeterminado.

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS is_someday BOOLEAN NOT NULL DEFAULT FALSE;

-- Indice para queries rapidas do filtro someday
CREATE INDEX IF NOT EXISTS idx_tasks_someday
  ON public.tasks(workspace_id, is_someday)
  WHERE is_someday = TRUE;
