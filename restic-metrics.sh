#!/bin/bash
source /home/.restic_env
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
export RESTIC_PASSWORD="$RESTIC_PASSWORD"
STATUS=${1:-FAIL}
# Base de datos SQLite
DB_FILE="/var/lib/grafana/restic_metrics.db"   


log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Crear tabla si no existe
init_db() {
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        snapshot_id TEXT,
        time TEXT,
        num_files INTEGER,
        total_size INTEGER,
        host TEXT,
        status TEXT
    );"
}

# Guardar métricas en la base de datos
save_metrics() {
    local SNAP_ID="$1"
    local SNAP_TIME="$2"
    local NUM_FILES="$3"
    local TOTAL_SIZE="$4"
    local HOST="$5"
    local STATUS="$6"

    sqlite3 "$DB_FILE" "INSERT INTO metrics (snapshot_id, time, num_files, total_size, host, status)
        VALUES ('$SNAP_ID', '$SNAP_TIME', $NUM_FILES, $TOTAL_SIZE, '$HOST', '$STATUS');"
}

init_db

# Obtener el último snapshot
SNAP_JSON=$(restic snapshots latest --json 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$SNAP_JSON" ] || [ "$SNAP_JSON" = "[]" ]; then
    log "Error: No hay snapshots disponibles o fallo al obtener snapshots"
    exit 1
fi

# Parsear datos del snapshot
SNAP_ID=$(echo "$SNAP_JSON" | jq -r '.[0].short_id')
SNAP_TIME=$(echo "$SNAP_JSON" | jq -r '.[0].time')
HOST=$(echo "$SNAP_JSON" | jq -r '.[0].hostname')

# Obtener estadísticas del último snapshot
STATS_JSON=$(restic stats latest --mode raw-data --json 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$STATS_JSON" ]; then
    log "Error al obtener estadísticas de Restic"
    exit 1
fi

# Parsear estadísticas
NUM_FILES=$(echo "$STATS_JSON" | jq -r '.total_file_count')
TOTAL_SIZE=$(echo "$STATS_JSON" | jq -r '.total_size')

# Valores por defecto para evitar NULL
SNAP_ID=${SNAP_ID:-"no_snapshot"}
SNAP_TIME=${SNAP_TIME:-"1970-01-01T00:00:00Z"}
NUM_FILES=${NUM_FILES:-0}
TOTAL_SIZE=${TOTAL_SIZE:-0}
HOST=${HOST:-"unknown"}

# Guardar métricas en SQLite
save_metrics "$SNAP_ID" "$SNAP_TIME" "$NUM_FILES" "$TOTAL_SIZE" "$HOST" "$STATUS"

log "Métricas guardadas en $DB_FILE"