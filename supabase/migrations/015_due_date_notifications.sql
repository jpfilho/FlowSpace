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
