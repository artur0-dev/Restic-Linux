#!/bin/bash
# restic-backup.sh
# Backup automático de archivos de configuración (local + B2)

# -------------------------
# CONFIGURACIÓN
# -------------------------
BACKUP_DIRS=(
    "/home/pruebas.txt"
    "/home/ids_mover_a_db.py"
)
LOG_FILE="/var/log/restic/restic-backup.log"
METRICS_SCRIPT="/home/restic-analythics.sh"

# Política de retención
RETENTION="--keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# -------------------------
# BACKUP LOCAL
# -------------------------
export RESTIC_REPOSITORY="/mnt/backups/restic-backups"
export RESTIC_PASSWORD="TuContraseñaSegura"

log "=== Iniciando backup LOCAL ==="
restic backup "${BACKUP_DIRS[@]}"
RETVAL_LOCAL=$?
if [ $RETVAL_LOCAL -eq 0 ]; then
    log "Backup LOCAL completado con éxito."
    $METRICS_SCRIPT OK
else
    log "Error: Backup LOCAL fallido."
    $METRICS_SCRIPT FAIL
fi

# -------------------------
# BACKUP NUBE (Backblaze B2)
# -------------------------
export RESTIC_REPOSITORY="b2:mi-backup-pruebas-seccion9-2026"
export B2_ACCOUNT_ID="tu_account_id"
export B2_ACCOUNT_KEY="tu_application_key"
export RESTIC_PASSWORD="TuContraseñaSegura"

log "=== Iniciando backup NUBE (B2) ==="
restic backup "${BACKUP_DIRS[@]}"
RETVAL_B2=$?

if [ $RETVAL_B2 -eq 0 ]; then
    log "Backup NUBE completado con éxito."
    $METRICS_SCRIPT OK
else
    log "Error: Backup NUBE fallido."
    $METRICS_SCRIPT FAIL
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
# -------------------------
# LIMPIAR SNAPSHOTS ANTIGUOS (solo local)
# -------------------------
restic forget $RETENTION --prune
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente (LOCAL)."
else
    log "Advertencia: Error al eliminar snapshots antiguos."
fi

log "=== Backup COMPLETO finalizado ==="