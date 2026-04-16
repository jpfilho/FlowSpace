-- ============================================================
-- FlowSpace — Migração 004: RLS para pages, blocks e task_comments
-- Execute no SQL Editor do Supabase Studio (localhost:54323)
-- ============================================================

-- ── RLS: pages ──────────────────────────────────────────────
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pages_select" ON public.pages;
DROP POLICY IF EXISTS "pages_insert" ON public.pages;
DROP POLICY IF EXISTS "pages_update" ON public.pages;
DROP POLICY IF EXISTS "pages_delete" ON public.pages;
DROP POLICY IF EXISTS "pages_select_member" ON public.pages;
DROP POLICY IF EXISTS "pages_insert_member" ON public.pages;
DROP POLICY IF EXISTS "pages_update_member" ON public.pages;

-- Membros do workspace podem ver páginas
CREATE POLICY "pages_select" ON public.pages
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- Membros podem criar páginas no workspace
CREATE POLICY "pages_insert" ON public.pages
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Membros podem atualizar páginas
CREATE POLICY "pages_update" ON public.pages
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- Apenas criador pode deletar
CREATE POLICY "pages_delete" ON public.pages
  FOR DELETE USING (created_by = auth.uid());

-- ── RLS: blocks ──────────────────────────────────────────────
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "blocks_select" ON public.blocks;
DROP POLICY IF EXISTS "blocks_insert" ON public.blocks;
DROP POLICY IF EXISTS "blocks_update" ON public.blocks;
DROP POLICY IF EXISTS "blocks_delete" ON public.blocks;

-- Membros do workspace podem ver blocos (via join com pages)
CREATE POLICY "blocks_select" ON public.blocks
  FOR SELECT USING (
    page_id IN (
      SELECT p.id FROM public.pages p
      JOIN public.workspace_members wm ON wm.workspace_id = p.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Membros podem criar blocos em páginas do workspace
CREATE POLICY "blocks_insert" ON public.blocks
  FOR INSERT WITH CHECK (
    page_id IN (
      SELECT p.id FROM public.pages p
      JOIN public.workspace_members wm ON wm.workspace_id = p.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Membros podem atualizar blocos
CREATE POLICY "blocks_update" ON public.blocks
  FOR UPDATE USING (
    page_id IN (
      SELECT p.id FROM public.pages p
      JOIN public.workspace_members wm ON wm.workspace_id = p.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Membros podem deletar blocos
CREATE POLICY "blocks_delete" ON public.blocks
  FOR DELETE USING (
    page_id IN (
      SELECT p.id FROM public.pages p
      JOIN public.workspace_members wm ON wm.workspace_id = p.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- ── RLS: task_comments ───────────────────────────────────────
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "task_comments_select" ON public.task_comments;
DROP POLICY IF EXISTS "task_comments_insert" ON public.task_comments;
DROP POLICY IF EXISTS "task_comments_update" ON public.task_comments;
DROP POLICY IF EXISTS "task_comments_update_own" ON public.task_comments;
DROP POLICY IF EXISTS "task_comments_delete" ON public.task_comments;

-- Membros do workspace podem ver comentários das tarefas
CREATE POLICY "task_comments_select" ON public.task_comments
  FOR SELECT USING (
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Membros podem comentar em tarefas do workspace
CREATE POLICY "task_comments_insert" ON public.task_comments
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid()
    )
    AND author_id = auth.uid()
  );

-- Apenas o autor pode editar o próprio comentário
CREATE POLICY "task_comments_update" ON public.task_comments
  FOR UPDATE USING (author_id = auth.uid());

-- Autor ou admin podem deletar
CREATE POLICY "task_comments_delete" ON public.task_comments
  FOR DELETE USING (
    author_id = auth.uid()
    OR
    task_id IN (
      SELECT t.id FROM public.tasks t
      JOIN public.workspace_members wm ON wm.workspace_id = t.workspace_id
      WHERE wm.user_id = auth.uid() AND wm.role IN ('admin', 'manager')
    )
  );

-- ── RLS: notifications ───────────────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;

CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "notifications_delete" ON public.notifications
  FOR DELETE USING (user_id = auth.uid());

-- O sistema (service role) pode inserir notificações
-- INSERT via service_role key, não precisa de policy para anon/user
