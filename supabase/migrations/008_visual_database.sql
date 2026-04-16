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
