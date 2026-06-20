-- Migration: Add SLA Columns to Tasks
ALTER TABLE public.tasks 
ADD COLUMN deadline_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN is_sla_critical BOOLEAN DEFAULT FALSE;

-- Index for Dashboard performance
CREATE INDEX idx_tasks_deadline_at ON public.tasks (deadline_at) WHERE status != 'done';

-- Trigger to automatically manage completed_at
CREATE OR REPLACE FUNCTION public.trg_tasks_set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'done' AND (OLD.status IS NULL OR OLD.status != 'done') THEN
    NEW.completed_at := NOW();
  ELSIF NEW.status != 'done' AND OLD.status = 'done' THEN
    NEW.completed_at := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tasks_set_completed_at_trigger
BEFORE UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.trg_tasks_set_completed_at();
