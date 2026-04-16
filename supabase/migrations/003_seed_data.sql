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
