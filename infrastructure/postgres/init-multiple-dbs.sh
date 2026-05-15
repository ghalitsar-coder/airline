#!/bin/sh
set -eu

create_database() {
  database_name="$1"
  # trim whitespace
  database_name=$(printf '%s' "$database_name" | tr -d '[:space:]')
  [ -z "$database_name" ] && return 0

  echo "Creating database ${database_name}"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    SELECT 'CREATE DATABASE ${database_name}'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${database_name}')\gexec
EOSQL
}

if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
  echo "Multiple database creation requested: ${POSTGRES_MULTIPLE_DATABASES}"
  # Comma-separated list → one CREATE DATABASE per name (read line-by-line breaks on spaces)
  OLDIFS=${IFS:-}
  IFS=','
  for database_name in $POSTGRES_MULTIPLE_DATABASES; do
    create_database "$database_name"
  done
  IFS=$OLDIFS
fi
