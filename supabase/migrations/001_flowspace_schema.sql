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
