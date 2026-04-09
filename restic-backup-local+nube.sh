#!/bin/bash
# restic-backup.sh
# Backup automático de archivos de configuración (local + B2)

# -------------------------
# CONFIGURACIÓN
# -------------------------
source /home/.restic_env


BACKUP_DIRS=(
    "/home/pruebas.txt"
    "/home/ids_mover_a_db.py"
)
LOG_FILE="/var/log/restic/restic-backup.log"
METRICS_SCRIPT="/home/restic-analythics.sh"

# Política de retención
RETENTION="--prune --keep-daily 14"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# -------------------------
# BACKUP LOCAL
# -------------------------
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
export RESTIC_PASSWORD="$RESTIC_PASSWORD"

log "=== Iniciando backup LOCAL ==="
restic backup "${BACKUP_DIRS[@]}" --quiet
RETVAL_LOCAL=$?

if [ $RETVAL_LOCAL -eq 0 ]; then
    log "Backup LOCAL completado con éxito."
    $METRICS_SCRIPT OK
else
    log "Error: Backup LOCAL fallido."
    $METRICS_SCRIPT FAIL
fi

restic forget $RETENTION --prune
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente (LOCAL)."
else
    log "Advertencia: Error al eliminar snapshots antiguos (LOCAL)."
fi

# -------------------------
# BACKUP NUBE (Backblaze B2)
# -------------------------
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_B2"
export B2_ACCOUNT_ID="$B2_ACCOUNT_ID"       # tu KeyID
export B2_ACCOUNT_KEY="$B2_ACCOUNT_KEY"      # tu Application Key
export RESTIC_PASSWORD="$RESTIC_PASSWORD"

log "=== Iniciando backup NUBE (B2) ==="
restic backup "${BACKUP_DIRS[@]}" --quiet
RETVAL_B2=$?

if [ $RETVAL_B2 -eq 0 ]; then
    log "Backup NUBE completado con éxito."
else
    log "Error: Backup NUBE fallido."
fi

restic forget $RETENTION --prune
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente (Nube)."
else
    log "Advertencia: Error al eliminar snapshots antiguos (Nube)."
fi

# -------------------------
# VERIFICACIÓN E INTEGRIDAD (solo local)
# -------------------------
restic check
if [ $? -eq 0 ]; then
    log "Verificación del repositorio LOCAL completada correctamente."
else
    log "Advertencia: Verificación fallida."
fi


log "=== Backup COMPLETO finalizado ==="
