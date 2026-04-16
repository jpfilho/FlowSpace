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
