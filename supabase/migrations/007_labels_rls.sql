-- ─────────────────────────────────────────────────────────────
-- 007 — RLS policies for labels & task_labels
-- ─────────────────────────────────────────────────────────────

-- Enable RLS
ALTER TABLE public.labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_labels ENABLE ROW LEVEL SECURITY;

-- ── Labels ───────────────────────────────────────────────────

-- Members can read labels from their workspace
CREATE POLICY "labels_select" ON public.labels
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- Members can create labels in their workspace
CREATE POLICY "labels_insert" ON public.labels
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- Members can update labels in their workspace
CREATE POLICY "labels_update" ON public.labels
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- Members can delete labels in their workspace
CREATE POLICY "labels_delete" ON public.labels
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- ── Task Labels (join table) ─────────────────────────────────

-- Members can read task-label associations for tasks in their workspace
CREATE POLICY "task_labels_select" ON public.task_labels
  FOR SELECT USING (
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Members can assign labels to tasks in their workspace
CREATE POLICY "task_labels_insert" ON public.task_labels
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Members can remove labels from tasks in their workspace
CREATE POLICY "task_labels_delete" ON public.task_labels
  FOR DELETE USING (
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );
