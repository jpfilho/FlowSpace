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
