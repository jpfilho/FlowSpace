-- ============================================================
-- FlowSpace — Calendar Events CRUD & RLS (010)
-- ============================================================

-- A tabela calendar_events já existe em 001 com colunas:
--   starts_at, ends_at, all_day, title, description, color

-- ── RLS para calendar_events ──────────────────────────────────
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view workspace calendar events" ON public.calendar_events;
CREATE POLICY "Users can view workspace calendar events"
  ON public.calendar_events FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can create calendar events" ON public.calendar_events;
CREATE POLICY "Users can create calendar events"
  ON public.calendar_events FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

DROP POLICY IF EXISTS "Users can update their calendar events" ON public.calendar_events;
CREATE POLICY "Users can update their calendar events"
  ON public.calendar_events FOR UPDATE
  USING (created_by = auth.uid());

DROP POLICY IF EXISTS "Users can delete their calendar events" ON public.calendar_events;
CREATE POLICY "Users can delete their calendar events"
  ON public.calendar_events FOR DELETE
  USING (created_by = auth.uid());

-- ── Índices para performance ───────────────────────────────────
CREATE INDEX IF NOT EXISTS calendar_events_workspace_starts_idx
  ON public.calendar_events (workspace_id, starts_at);

-- ── RPC: busca eventos por período ────────────────────────────
CREATE OR REPLACE FUNCTION public.get_calendar_range(
  p_workspace  UUID,
  p_start      DATE,
  p_end        DATE
)
RETURNS TABLE (
  id          UUID,
  title       TEXT,
  starts_at   TIMESTAMPTZ,
  ends_at     TIMESTAMPTZ,
  color       TEXT,
  all_day     BOOLEAN,
  description TEXT,
  event_type  TEXT,  -- 'event' | 'task'
  task_id     UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  -- Eventos reais do calendário
  SELECT
    ce.id,
    ce.title,
    ce.starts_at,
    ce.ends_at,
    ce.color,
    ce.all_day,
    ce.description,
    'event'::TEXT AS event_type,
    ce.task_id
  FROM public.calendar_events ce
  WHERE ce.workspace_id = p_workspace
    AND ce.starts_at::date <= p_end
    AND COALESCE(ce.ends_at, ce.starts_at)::date >= p_start

  UNION ALL

  -- Tarefas com due_date no período (como eventos)
  SELECT
    t.id,
    t.title,
    t.due_date::TIMESTAMPTZ,
    t.due_date::TIMESTAMPTZ,
    CASE t.priority
      WHEN 'urgent' THEN '#EF4444'
      WHEN 'high'   THEN '#F59E0B'
      WHEN 'medium' THEN '#5B6AF3'
      ELSE '#6B7280'
    END,
    TRUE,
    t.description,
    'task'::TEXT AS event_type,
    NULL::UUID
  FROM public.tasks t
  WHERE t.workspace_id = p_workspace
    AND t.due_date IS NOT NULL
    AND t.due_date::date BETWEEN p_start AND p_end
    AND t.status != 'done'

  ORDER BY starts_at ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_calendar_range TO authenticated;

COMMENT ON FUNCTION public.get_calendar_range IS
  'Retorna eventos de calendário + tarefas com prazo para um período específico';
