-- ============================================================
-- FlowSpace — Schema inicial do banco de dados Supabase
-- Execute no SQL Editor do Supabase Studio (localhost:54323)
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT '',
  avatar_url  TEXT,
  bio         TEXT,
  timezone    TEXT DEFAULT 'America/Sao_Paulo',
  language    TEXT DEFAULT 'pt-BR',
  theme       TEXT DEFAULT 'system', -- light | dark | system
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Workspaces ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workspaces (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  slug        TEXT UNIQUE NOT NULL,
  description TEXT,
  logo_url    TEXT,
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.workspace_members (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role         TEXT NOT NULL DEFAULT 'collaborator', -- admin | manager | collaborator | viewer
  joined_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(workspace_id, user_id)
);

-- ── Areas ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.areas (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT,
  color        TEXT DEFAULT '#5B6AF3',
  icon         TEXT DEFAULT 'folder',
  position     INT DEFAULT 0,
  created_by   UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── Projects ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.projects (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  area_id      UUID REFERENCES public.areas(id) ON DELETE SET NULL,
  name         TEXT NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'active', -- active | on_hold | completed | cancelled
  priority     TEXT DEFAULT 'medium',
  start_date   DATE,
  end_date     DATE,
  color        TEXT DEFAULT '#5B6AF3',
  cover_url    TEXT,
  progress     INT DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  owner_id     UUID REFERENCES public.profiles(id),
  created_by   UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.project_members (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role       TEXT DEFAULT 'member', -- owner | manager | member | viewer
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, user_id)
);

-- ── Labels ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.labels (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  color        TEXT NOT NULL DEFAULT '#5B6AF3',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tasks ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tasks (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  project_id   UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  parent_id    UUID REFERENCES public.tasks(id) ON DELETE CASCADE, -- subtasks
  title        TEXT NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'todo', -- todo | in_progress | review | done | cancelled
  priority     TEXT NOT NULL DEFAULT 'medium', -- urgent | high | medium | low
  due_date     TIMESTAMPTZ,
  start_date   TIMESTAMPTZ,
  estimated_hours DECIMAL(6,2),
  actual_hours    DECIMAL(6,2),
  assignee_id  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_by   UUID REFERENCES public.profiles(id),
  position     INT DEFAULT 0,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence   JSONB, -- { frequency, interval, end_date, etc }
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.task_labels (
  task_id  UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  label_id UUID NOT NULL REFERENCES public.labels(id) ON DELETE CASCADE,
  PRIMARY KEY (task_id, label_id)
);

CREATE TABLE IF NOT EXISTS public.task_comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id    UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.task_attachments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id     UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  uploader_id UUID REFERENCES public.profiles(id),
  name        TEXT NOT NULL,
  url         TEXT NOT NULL,
  size_bytes  BIGINT,
  mime_type   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Pages / Documents ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pages (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  parent_id    UUID REFERENCES public.pages(id) ON DELETE CASCADE,
  project_id   UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  title        TEXT NOT NULL DEFAULT 'Sem título',
  icon         TEXT,
  cover_url    TEXT,
  is_favorite  BOOLEAN DEFAULT FALSE,
  position     INT DEFAULT 0,
  created_by   UUID REFERENCES public.profiles(id),
  last_edited_by UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.blocks (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id    UUID NOT NULL REFERENCES public.pages(id) ON DELETE CASCADE,
  parent_id  UUID REFERENCES public.blocks(id) ON DELETE CASCADE,
  type       TEXT NOT NULL DEFAULT 'paragraph',
  -- Types: paragraph | heading1 | heading2 | heading3 | bulleted_list |
  --        numbered_list | checklist | quote | callout | code | image |
  --        divider | table | toggle | embed | video | file
  content    JSONB DEFAULT '{}',
  position   INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Calendário ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  task_id      UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  description  TEXT,
  starts_at    TIMESTAMPTZ NOT NULL,
  ends_at      TIMESTAMPTZ,
  all_day      BOOLEAN DEFAULT FALSE,
  color        TEXT DEFAULT '#5B6AF3',
  location     TEXT,
  created_by   UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── Notifications ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE,
  type         TEXT NOT NULL, -- task_assigned, comment, mention, project_update, etc
  title        TEXT NOT NULL,
  body         TEXT,
  data         JSONB DEFAULT '{}',
  is_read      BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── Activities ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.activities (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  actor_id     UUID REFERENCES public.profiles(id),
  entity_type  TEXT NOT NULL, -- task | project | page | comment
  entity_id    UUID NOT NULL,
  action       TEXT NOT NULL, -- created | updated | deleted | completed | commented
  data         JSONB DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── GTD ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.gtd_inbox (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE,
  content      TEXT NOT NULL,
  is_processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMPTZ,
  task_id      UUID REFERENCES public.tasks(id) ON DELETE SET NULL, -- link pós-esclarecer
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gtd_contexts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL, -- @casa, @trabalho, @computador, @telefone
  color        TEXT DEFAULT '#5B6AF3',
  icon         TEXT DEFAULT 'place',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── User Preferences ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id               UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  default_workspace_id  UUID REFERENCES public.workspaces(id),
  sidebar_collapsed     BOOLEAN DEFAULT FALSE,
  task_default_view     TEXT DEFAULT 'list', -- list | kanban | calendar | table
  notifications_email   BOOLEAN DEFAULT TRUE,
  notifications_push    BOOLEAN DEFAULT TRUE,
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── Índices ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tasks_workspace ON public.tasks(workspace_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_pages_workspace ON public.pages(workspace_id);
CREATE INDEX IF NOT EXISTS idx_pages_parent ON public.pages(parent_id);
CREATE INDEX IF NOT EXISTS idx_blocks_page ON public.blocks(page_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_activities_workspace ON public.activities(workspace_id);
CREATE INDEX IF NOT EXISTS idx_gtd_inbox_user ON public.gtd_inbox(user_id, is_processed);

-- ── Trigger: atualizar updated_at automaticamente ─────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trigger_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trigger_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trigger_pages_updated_at
  BEFORE UPDATE ON public.pages
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ── Trigger: criar perfil automaticamente ao criar usuário ──
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
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
-- FlowSpace seed data para testes de integração
-- NOTA: o profile do usuário é criado automaticamente via trigger auth.users
-- Este seed apenas garante que os dados de workspace e conteúdo existam
DO $$
DECLARE
  v_workspace_id UUID := 'd9cee4b1-c843-4c35-bb93-f3d3a369e06a';
  v_user_id UUID := '87ad79cd-7fcc-4c70-b924-d84ce5fb888d';
  v_project_id UUID;
BEGIN

-- Tentar criar profile seed (pode falhar se usuário não existir em auth.users, o que é normal)
-- O profile real é criado via trigger quando o usuário se cadastra
BEGIN
  INSERT INTO public.profiles (id, name, avatar_url)
  VALUES (v_user_id, 'Usuário Demo', NULL)
  ON CONFLICT (id) DO NOTHING;
EXCEPTION WHEN foreign_key_violation THEN
  -- Usuário não existe em auth.users ainda, skip
  RAISE NOTICE 'Profile seed ignorado - usuário não existe em auth.users';
  RETURN;
END;

-- Criar workspace (deve existir antes dos membros)
INSERT INTO public.workspaces (id, name, slug, description, owner_id)
VALUES (v_workspace_id, 'Workspace Demo', 'workspace-demo', 'Workspace de demonstração do FlowSpace', v_user_id)
ON CONFLICT (id) DO NOTHING;

-- Adicionar usuário como admin do workspace
INSERT INTO public.workspace_members (workspace_id, user_id, role)
VALUES (v_workspace_id, v_user_id, 'admin')
ON CONFLICT (workspace_id, user_id) DO NOTHING;

-- Criar áreas padrão
INSERT INTO public.areas (workspace_id, name, description, color, created_by)
VALUES 
  (v_workspace_id, 'Pessoal', 'Projetos e tarefas pessoais', '#5B6AF3', v_user_id),
  (v_workspace_id, 'Trabalho', 'Projetos profissionais', '#06B6D4', v_user_id),
  (v_workspace_id, 'Estudos', 'Aprendizado e cursos', '#22C55E', v_user_id);

-- Criar projeto demo
v_project_id := uuid_generate_v4();
INSERT INTO public.projects (id, workspace_id, name, description, status, priority, progress, owner_id, created_by)
VALUES (
  v_project_id, v_workspace_id, 'FlowSpace MVP',
  'Implementação da plataforma de produtividade',
  'active', 'high', 45, v_user_id, v_user_id
);

-- Criar labels
INSERT INTO public.labels (workspace_id, name, color)
VALUES
  (v_workspace_id, 'Frontend', '#5B6AF3'),
  (v_workspace_id, 'Backend', '#06B6D4'),
  (v_workspace_id, 'Design', '#F59E0B'),
  (v_workspace_id, 'Bug', '#EF4444'),
  (v_workspace_id, 'Feature', '#22C55E')
ON CONFLICT DO NOTHING;

-- Criar tarefas de teste
INSERT INTO public.tasks (workspace_id, project_id, title, description, status, priority, assignee_id, created_by, due_date)
VALUES
  (v_workspace_id, v_project_id, 'Implementar autenticação Supabase', 'Login, signup, sessão persistente', 'done', 'urgent', v_user_id, v_user_id, NOW() - INTERVAL '1 day'),
  (v_workspace_id, v_project_id, 'Criar Design System completo', 'Tokens, componentes, tema light/dark', 'in_progress', 'high', v_user_id, v_user_id, NOW()),
  (v_workspace_id, v_project_id, 'Modelar banco PostgreSQL', 'Schema, índices, RLS, triggers', 'done', 'high', v_user_id, v_user_id, NOW() - INTERVAL '2 days'),
  (v_workspace_id, v_project_id, 'Implementar sidebar responsiva', 'Desktop/tablet/mobile', 'in_progress', 'medium', v_user_id, v_user_id, NOW() + INTERVAL '1 day'),
  (v_workspace_id, v_project_id, 'Dashboard com stat cards', 'Cards de resumo e atividade recente', 'todo', 'medium', v_user_id, v_user_id, NOW() + INTERVAL '3 days'),
  (v_workspace_id, v_project_id, 'Módulo GTD com captura rápida', 'Inbox, next actions, contexts', 'todo', 'low', v_user_id, v_user_id, NOW() + INTERVAL '7 days'),
  (v_workspace_id, v_project_id, 'Editor de páginas em blocos', 'Texto, títulos, checklists, código', 'todo', 'medium', v_user_id, v_user_id, NOW() + INTERVAL '10 days');

-- Criar entradas GTD inbox
INSERT INTO public.gtd_inbox (user_id, workspace_id, content)
VALUES
  (v_user_id, v_workspace_id, 'Estudar Riverpod 3.0 para migração futura'),
  (v_user_id, v_workspace_id, 'Pesquisar soluções de sync offline-first para Flutter'),
  (v_user_id, v_workspace_id, 'Criar template de revisão semanal GTD'),
  (v_user_id, v_workspace_id, 'Configurar CI/CD para deploy automático');

-- Criar evento de calendário
INSERT INTO public.calendar_events (workspace_id, title, description, starts_at, ends_at, color, created_by)
VALUES (
  v_workspace_id, 'Revisão semanal GTD',
  'Revisar todas as áreas e próximas ações',
  NOW() + INTERVAL '2 days',
  NOW() + INTERVAL '2 days' + INTERVAL '1 hour',
  '#5B6AF3', v_user_id
);

-- Criar contextos GTD
INSERT INTO public.gtd_contexts (user_id, name, color)
VALUES
  (v_user_id, '@computador', '#5B6AF3'),
  (v_user_id, '@telefone', '#22C55E'),
  (v_user_id, '@casa', '#F59E0B'),
  (v_user_id, '@trabalho', '#06B6D4')
ON CONFLICT DO NOTHING;

-- Criar página de exemplo
INSERT INTO public.pages (workspace_id, project_id, title, icon, created_by, last_edited_by)
VALUES (
  v_workspace_id, v_project_id, 'Notas do Projeto FlowSpace', '📝', v_user_id, v_user_id
);

-- Criar preferências do usuário
INSERT INTO public.user_preferences (user_id, default_workspace_id, task_default_view)
VALUES (v_user_id, v_workspace_id, 'list')
ON CONFLICT (user_id) DO UPDATE SET
  default_workspace_id = EXCLUDED.default_workspace_id;

RAISE NOTICE 'Seed completo com sucesso!';
END
$$;
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
-- ============================================================
-- FlowSpace — Busca Fulltext Unificada (005)
-- ============================================================

-- ── Habilita a extensão de busca fulltext (já ativa por padrão) ──
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ── Adiciona colunas de tsvector ─────────────────────────────
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('portuguese', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('portuguese', coalesce(description, '')), 'B')
  ) STORED;

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('portuguese', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('portuguese', coalesce(description, '')), 'B')
  ) STORED;

ALTER TABLE public.pages
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('portuguese', coalesce(title, '')), 'A')
  ) STORED;

-- ── Índices GIN para performance ──────────────────────────────
CREATE INDEX IF NOT EXISTS tasks_search_vector_idx
  ON public.tasks USING gin(search_vector);

CREATE INDEX IF NOT EXISTS projects_search_vector_idx
  ON public.projects USING gin(search_vector);

CREATE INDEX IF NOT EXISTS pages_search_vector_idx
  ON public.pages USING gin(search_vector);

-- ── Função RPC: search_all ────────────────────────────────────
-- Retorna resultados unificados de tasks, projects e pages
-- Suporta tsvector quando possível, fallback para ILIKE
CREATE OR REPLACE FUNCTION public.search_all(
  p_query       TEXT,
  p_workspace   UUID,
  p_user_id     UUID,
  p_limit       INT DEFAULT 20
)
RETURNS TABLE (
  id          UUID,
  title       TEXT,
  subtitle    TEXT,
  result_type TEXT,    -- 'task' | 'project' | 'page'
  status_icon TEXT,
  rank        REAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tsquery tsquery;
BEGIN
  -- Build tsquery safely
  BEGIN
    v_tsquery := websearch_to_tsquery('portuguese', p_query);
  EXCEPTION WHEN OTHERS THEN
    v_tsquery := NULL;
  END;

  RETURN QUERY
  -- Tasks
  SELECT
    t.id,
    t.title,
    COALESCE('Projeto: ' || pr.name, t.status)  AS subtitle,
    'task'::TEXT                                  AS result_type,
    t.status                                      AS status_icon,
    CASE
      WHEN v_tsquery IS NOT NULL THEN ts_rank(t.search_vector, v_tsquery)
      ELSE 0.5
    END                                           AS rank
  FROM public.tasks t
  LEFT JOIN public.projects pr ON pr.id = t.project_id
  WHERE
    t.workspace_id = p_workspace
    AND (
      (v_tsquery IS NOT NULL AND t.search_vector @@ v_tsquery)
      OR t.title ILIKE '%' || p_query || '%'
      OR t.description ILIKE '%' || p_query || '%'
    )

  UNION ALL

  -- Projects
  SELECT
    p.id,
    p.name                                        AS title,
    COALESCE(LEFT(p.description, 80), p.status)   AS subtitle,
    'project'::TEXT                               AS result_type,
    p.status                                      AS status_icon,
    CASE
      WHEN v_tsquery IS NOT NULL THEN ts_rank(p.search_vector, v_tsquery)
      ELSE 0.5
    END                                           AS rank
  FROM public.projects p
  WHERE
    p.workspace_id = p_workspace
    AND (
      (v_tsquery IS NOT NULL AND p.search_vector @@ v_tsquery)
      OR p.name  ILIKE '%' || p_query || '%'
      OR p.description ILIKE '%' || p_query || '%'
    )

  UNION ALL

  -- Pages
  SELECT
    pg.id,
    pg.title,
    NULL::TEXT                                    AS subtitle,
    'page'::TEXT                                  AS result_type,
    pg.icon                                       AS status_icon,
    CASE
      WHEN v_tsquery IS NOT NULL THEN ts_rank(pg.search_vector, v_tsquery)
      ELSE 0.5
    END                                           AS rank
  FROM public.pages pg
  WHERE
    pg.workspace_id = p_workspace
    AND pg.created_by = p_user_id
    AND (
      (v_tsquery IS NOT NULL AND pg.search_vector @@ v_tsquery)
      OR pg.title ILIKE '%' || p_query || '%'
    )

  ORDER BY rank DESC, title
  LIMIT p_limit;
END;
$$;

-- Grant execute para authenticated
GRANT EXECUTE ON FUNCTION public.search_all TO authenticated;

COMMENT ON FUNCTION public.search_all IS
  'Busca fulltext unificada: tasks + projects + pages com tsvector ranking';
-- ============================================================
-- FlowSpace — Sistema de Convites (006)
-- ============================================================

-- ── Tabela de convites ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workspace_invites (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id  UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  invited_by    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT NOT NULL DEFAULT 'member', -- owner | admin | member
  status        TEXT NOT NULL DEFAULT 'pending', -- pending | accepted | declined | expired
  token         TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  message       TEXT,
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  accepted_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Índices ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS workspace_invites_workspace_idx
  ON public.workspace_invites(workspace_id);

CREATE INDEX IF NOT EXISTS workspace_invites_email_idx
  ON public.workspace_invites(invited_email);

CREATE INDEX IF NOT EXISTS workspace_invites_token_idx
  ON public.workspace_invites(token);

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE public.workspace_invites ENABLE ROW LEVEL SECURITY;

-- Admins do workspace podem ver todos os convites
CREATE POLICY "workspace_admins_view_invites"
  ON public.workspace_invites FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = workspace_invites.workspace_id
        AND wm.user_id = auth.uid()
        AND wm.role IN ('owner', 'admin')
    )
  );

-- Admins podem criar convites
CREATE POLICY "workspace_admins_create_invites"
  ON public.workspace_invites FOR INSERT
  WITH CHECK (
    invited_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = workspace_invites.workspace_id
        AND wm.user_id = auth.uid()
        AND wm.role IN ('owner', 'admin')
    )
  );

-- Admins podem cancelar convites do seu workspace
CREATE POLICY "workspace_admins_delete_invites"
  ON public.workspace_invites FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = workspace_invites.workspace_id
        AND wm.user_id = auth.uid()
        AND wm.role IN ('owner', 'admin')
    )
  );

-- ── Função: aceitar convite ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.accept_workspace_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite workspace_invites%ROWTYPE;
  v_user_email TEXT;
BEGIN
  -- Get current user email
  SELECT email INTO v_user_email
  FROM auth.users WHERE id = auth.uid();

  -- Get invite
  SELECT * INTO v_invite
  FROM public.workspace_invites
  WHERE token = p_token
    AND status = 'pending'
    AND expires_at > NOW();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Convite inválido ou expirado');
  END IF;

  IF v_invite.invited_email <> v_user_email THEN
    RETURN jsonb_build_object('error', 'Este convite pertence a outro email');
  END IF;

  -- Check if already a member
  IF EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = v_invite.workspace_id AND user_id = auth.uid()
  ) THEN
    -- Update invite status and return success anyway
    UPDATE public.workspace_invites
    SET status = 'accepted', accepted_at = NOW()
    WHERE id = v_invite.id;
    RETURN jsonb_build_object('success', true, 'workspace_id', v_invite.workspace_id);
  END IF;

  -- Add to workspace
  INSERT INTO public.workspace_members(workspace_id, user_id, role)
  VALUES (v_invite.workspace_id, auth.uid(), v_invite.role)
  ON CONFLICT DO NOTHING;

  -- Mark accepted
  UPDATE public.workspace_invites
  SET status = 'accepted', accepted_at = NOW()
  WHERE id = v_invite.id;

  RETURN jsonb_build_object('success', true, 'workspace_id', v_invite.workspace_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_workspace_invite TO authenticated;

-- ── Função: listar membros do workspace ───────────────────────
CREATE OR REPLACE FUNCTION public.list_workspace_members(p_workspace UUID)
RETURNS TABLE (
  user_id   UUID,
  name      TEXT,
  email     TEXT,
  avatar    TEXT,
  role      TEXT,
  joined_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    wm.user_id,
    COALESCE(p.name, u.email) AS name,
    u.email,
    p.avatar_url AS avatar,
    wm.role,
    wm.created_at AS joined_at
  FROM public.workspace_members wm
  JOIN auth.users u ON u.id = wm.user_id
  LEFT JOIN public.profiles p ON p.id = wm.user_id
  WHERE wm.workspace_id = p_workspace
  ORDER BY wm.role DESC, wm.created_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.list_workspace_members TO authenticated;

COMMENT ON TABLE public.workspace_invites IS
  'Convites de email para workspace — token único de 7 dias';
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
-- ─────────────────────────────────────────────────────────────
-- 008 — Visual Databases (Airtable-style)
-- ─────────────────────────────────────────────────────────────

-- ── Databases ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.databases (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT,
  icon         TEXT,
  color        TEXT DEFAULT '#5B6AF3',
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.databases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "databases_select" ON public.databases
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "databases_insert" ON public.databases
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "databases_update" ON public.databases
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "databases_delete" ON public.databases
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

-- ── Columns ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.db_columns (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  database_id UUID NOT NULL REFERENCES public.databases(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'text', -- text, number, date, select, checkbox
  position    INT DEFAULT 0,
  width       INT DEFAULT 200,
  options     JSONB, -- For 'select' type: { "choices": [{ "id": "1", "name": "A", "color": "blue" }] }
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.db_columns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "db_columns_select" ON public.db_columns
  FOR SELECT USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_columns_insert" ON public.db_columns
  FOR INSERT WITH CHECK (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_columns_update" ON public.db_columns
  FOR UPDATE USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_columns_delete" ON public.db_columns
  FOR DELETE USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- ── Rows ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.db_rows (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  database_id UUID NOT NULL REFERENCES public.databases(id) ON DELETE CASCADE,
  position    INT DEFAULT 0,
  data        JSONB DEFAULT '{}'::jsonb, -- Mapping of column_id -> value
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.db_rows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "db_rows_select" ON public.db_rows
  FOR SELECT USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_rows_insert" ON public.db_rows
  FOR INSERT WITH CHECK (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_rows_update" ON public.db_rows
  FOR UPDATE USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

CREATE POLICY "db_rows_delete" ON public.db_rows
  FOR DELETE USING (
    database_id IN (
      SELECT d.id FROM public.databases d
      JOIN public.workspace_members wm ON wm.workspace_id = d.workspace_id
      WHERE wm.user_id = auth.uid()
    )
  );

-- Function to handle timestamp updates uniformly
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_databases_updated_at BEFORE UPDATE ON public.databases FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
CREATE TRIGGER update_db_columns_updated_at BEFORE UPDATE ON public.db_columns FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
CREATE TRIGGER update_db_rows_updated_at BEFORE UPDATE ON public.db_rows FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
-- ============================================================
-- FlowSpace — Auto-criação de Workspace no Signup (009)
-- ============================================================
-- O migration 001 já cria o trigger on_auth_user_created com
-- uma função básica que só cria o profile.
-- Aqui substituímos a função para também criar o workspace.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_workspace_id  UUID;
  v_user_name     TEXT;
  v_slug          TEXT;
BEGIN
  -- Pega nome do metadata ou extrai do email
  v_user_name := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'name'), ''),
    split_part(NEW.email, '@', 1)
  );

  -- Cria perfil do usuário (ON CONFLICT pois migration 001 pode ter criado)
  INSERT INTO public.profiles (id, name, bio, created_at, updated_at)
  VALUES (
    NEW.id,
    v_user_name,
    '',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

  -- Gera slug único para o workspace
  v_slug := lower(regexp_replace(
    coalesce(v_user_name, 'user'), '[^a-zA-Z0-9]', '-', 'g'
  )) || '-' || substr(gen_random_uuid()::text, 1, 8);

  -- Cria workspace pessoal para o usuário
  INSERT INTO public.workspaces (id, name, slug, owner_id, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    v_user_name || '''s Workspace',
    v_slug,
    NEW.id,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_workspace_id;

  -- Adiciona usuário como admin do workspace
  INSERT INTO public.workspace_members (workspace_id, user_id, role, joined_at)
  VALUES (v_workspace_id, NEW.id, 'admin', NOW())
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

-- O trigger já existe desde migration 001, apenas atualiza a função
-- Caso seja necessário recriar:
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION public.handle_new_user() IS
  'Cria automaticamente perfil + workspace pessoal ao registrar novo usuário';
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
-- ============================================================
-- FlowSpace -- RPC publica para preview de convite (011)
-- ============================================================
-- Permite que qualquer pessoa (mesmo sem autenticacao) veja
-- informacoes basicas de um convite pelo token unico.
-- O RPC accept_workspace_invite ainda valida o email do usuario.

CREATE OR REPLACE FUNCTION public.get_invite_preview(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite workspace_invites%ROWTYPE;
  v_workspace_name TEXT;
BEGIN
  SELECT wi.* INTO v_invite
  FROM public.workspace_invites wi
  WHERE wi.token = p_token
    AND wi.status = 'pending'
    AND wi.expires_at > NOW();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Convite nao encontrado ou expirado');
  END IF;

  SELECT name INTO v_workspace_name
  FROM public.workspaces
  WHERE id = v_invite.workspace_id;

  RETURN jsonb_build_object(
    'invited_email', v_invite.invited_email,
    'role', v_invite.role,
    'expires_at', v_invite.expires_at,
    'workspace_name', v_workspace_name
  );
END;
$$;

-- Acessivel por usuarios anonimos (link de convite publico)
GRANT EXECUTE ON FUNCTION public.get_invite_preview TO anon, authenticated;
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
-- Migration 014: Recurring Tasks
-- Adds recurrence columns to tasks (applied directly, mirrors DDL above)

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS recurrence_type     TEXT    DEFAULT 'none'
    CHECK (recurrence_type IN ('none','daily','weekly','monthly','yearly')),
  ADD COLUMN IF NOT EXISTS recurrence_interval INT     DEFAULT 1 CHECK (recurrence_interval > 0),
  ADD COLUMN IF NOT EXISTS recurrence_ends_at  TIMESTAMPTZ DEFAULT NULL;
-- Migration 015: Due Date Notifications
CREATE OR REPLACE FUNCTION public.create_due_date_notifications_for_user(p_user_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO public.notifications (user_id, workspace_id, title, description, link_to)
  SELECT 
    t.assignee_id,
    t.workspace_id,
    'Prazo próximo: ' || t.title,
    'A tarefa vence ' || CASE WHEN t.due_date::date = CURRENT_DATE THEN 'hoje' ELSE 'amanhã' END || '.',
    '/tasks/' || t.id
  FROM public.tasks t
  WHERE 
    t.assignee_id = p_user_id
    AND t.status != 'done'
    AND t.due_date IS NOT NULL
    AND t.due_date >= CURRENT_DATE
    AND t.due_date < CURRENT_DATE + interval '2 days'
    -- Ensure we don't spam notifications
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.user_id = t.assignee_id
        AND n.link_to = '/tasks/' || t.id
        AND n.title LIKE 'Prazo próximo:%'
        AND n.created_at >= CURRENT_DATE - interval '1 day'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
