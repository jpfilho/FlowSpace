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
