#!/bin/bash
# Script to restore the FlowSpace database on the VPS

echo "===================================================="
echo " FlowSpace - Restoring database schema and backups"
echo "===================================================="

# Check if database container is running
if ! docker ps | grep -q "supabase-db"; then
  echo "Error: supabase-db container is not running!"
  exit 1
fi

echo "[1/3] Applying all migrations (including AI tables)..."
docker exec -i supabase-db psql -U postgres -d postgres < all_migrations_flowspace.sql

echo "[2/3] Restoring Auth schema data backup..."
docker exec -i supabase-db psql -U postgres -d postgres < data_backup_auth.sql

echo "[3/3] Restoring Public schema data backup..."
docker exec -i supabase-db psql -U postgres -d postgres < data_backup_public.sql

echo "Reloading PostgREST schema cache..."
docker exec -i supabase-db psql -U postgres -d postgres -c "NOTIFY pgrst, 'reload schema';"

echo "===================================================="
echo " Restore completed successfully!"
echo "===================================================="
