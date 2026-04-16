-- Migration 014: Recurring Tasks
-- Adds recurrence columns to tasks (applied directly, mirrors DDL above)

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS recurrence_type     TEXT    DEFAULT 'none'
    CHECK (recurrence_type IN ('none','daily','weekly','monthly','yearly')),
  ADD COLUMN IF NOT EXISTS recurrence_interval INT     DEFAULT 1 CHECK (recurrence_interval > 0),
  ADD COLUMN IF NOT EXISTS recurrence_ends_at  TIMESTAMPTZ DEFAULT NULL;
