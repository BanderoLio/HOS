#!/bin/sh
DATABASE_URL="postgresql://hos_admin:HOS_Admin@localhost:5432/hos?schema=public"
set -e

echo "Starting in development mode..."
exec npm run dev -- --port 5480 --host 0.0.0.0