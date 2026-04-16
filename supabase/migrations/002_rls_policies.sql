-- ============================================================
-- FlowSpace — Políticas de Row Level Security (RLS)
-- Execute APÓS o schema 001
-- ============================================================

-- ── Habilitar RLS em todas as tabelas ─────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gtd_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gtd_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- ── Helper: verificar se usuário é membro do workspace ────────
CREATE OR REPLACE FUNCTION public.is_workspace_member(p_workspace_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = p_workspace_id AND user_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── Profiles ──────────────────────────────────────────────────
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- ── Workspaces ────────────────────────────────────────────────
CREATE POLICY "workspaces_select_member" ON public.workspaces
  FOR SELECT USING (public.is_workspace_member(id));

CREATE POLICY "workspaces_insert_authenticated" ON public.workspaces
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "workspaces_update_owner" ON public.workspaces
  FOR UPDATE USING (owner_id = auth.uid());

-- ── Workspace Members ─────────────────────────────────────────
CREATE POLICY "workspace_members_select" ON public.workspace_members
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "workspace_members_insert_admin" ON public.workspace_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = workspace_members.workspace_id
        AND wm.user_id = auth.uid()
        AND wm.role IN ('admin', 'manager')
    )
  );

-- ── Tasks ─────────────────────────────────────────────────────
CREATE POLICY "tasks_select_member" ON public.tasks
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "tasks_insert_member" ON public.tasks
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "tasks_update_member" ON public.tasks
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

CREATE POLICY "tasks_delete_owner" ON public.tasks
  FOR DELETE USING (
    created_by = auth.uid() OR
    assignee_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = tasks.workspace_id
        AND wm.user_id = auth.uid()
        AND wm.role IN ('admin', 'manager')
    )
  );

-- ── Projects ──────────────────────────────────────────────────
CREATE POLICY "projects_select_member" ON public.projects
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "projects_insert_member" ON public.projects
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "projects_update_member" ON public.projects
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

-- ── Pages ─────────────────────────────────────────────────────
CREATE POLICY "pages_select_member" ON public.pages
  FOR SELECT USING (public.is_workspace_member(workspace_id));

CREATE POLICY "pages_insert_member" ON public.pages
  FOR INSERT WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY "pages_update_member" ON public.pages
  FOR UPDATE USING (public.is_workspace_member(workspace_id));

-- ── Blocks ────────────────────────────────────────────────────
CREATE POLICY "blocks_select" ON public.blocks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pages p
      WHERE p.id = blocks.page_id
        AND public.is_workspace_member(p.workspace_id)
    )
  );

CREATE POLICY "blocks_insert" ON public.blocks
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pages p
      WHERE p.id = blocks.page_id
        AND public.is_workspace_member(p.workspace_id)
    )
  );

-- ── Notifications ─────────────────────────────────────────────
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

-- ── GTD Inbox ─────────────────────────────────────────────────
CREATE POLICY "gtd_inbox_own" ON public.gtd_inbox
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "gtd_contexts_own" ON public.gtd_contexts
  FOR ALL USING (user_id = auth.uid());

-- ── User Preferences ──────────────────────────────────────────
CREATE POLICY "user_preferences_own" ON public.user_preferences
  FOR ALL USING (user_id = auth.uid());

-- ── Task Comments ─────────────────────────────────────────────
CREATE POLICY "task_comments_select" ON public.task_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_comments.task_id
        AND public.is_workspace_member(t.workspace_id)
    )
  );

CREATE POLICY "task_comments_insert" ON public.task_comments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_comments.task_id
        AND public.is_workspace_member(t.workspace_id)
    )
  );

CREATE POLICY "task_comments_update_own" ON public.task_comments
  FOR UPDATE USING (author_id = auth.uid());

-- ── Calendar Events ───────────────────────────────────────────
CREATE POLICY "calendar_events_member" ON public.calendar_events
  FOR ALL USING (public.is_workspace_member(workspace_id));
