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
