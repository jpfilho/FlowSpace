-- Migration 013: Task Attachments
-- Creates task_attachments table and Supabase Storage bucket policy

-- Table
CREATE TABLE IF NOT EXISTS public.task_attachments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id       UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  uploaded_by   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name     TEXT NOT NULL,
  file_size     BIGINT NOT NULL DEFAULT 0,
  mime_type     TEXT NOT NULL DEFAULT 'application/octet-stream',
  storage_path  TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id
  ON public.task_attachments(task_id);

-- RLS
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members can manage attachments"
  ON public.task_attachments
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE t.id = task_attachments.task_id
        AND wm.user_id = auth.uid()
    )
  );
