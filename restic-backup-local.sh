#!/bin/bash
# Repositorio Restic (local)

source /home/.restic_env
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
export RESTIC_PASSWORD="$RESTIC_PASSWORD"

# Directorios a respaldar
BACKUP_DIRS=(
        "/etc/cron.d"
        "/home/ids_mover_a_db.py"
)
# Archivo de log
LOG_FILE=/var/log/restic/restic-backup.log

#Mantiene 1 snapshot por día
#Máximo 14 días
#Todo lo más antiguo se elimina automáticamente
RETENTION="--prune --keep-daily 14"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "=== Iniciando backup Restic ==="

# hacer backup de la lista de carpetas
restic backup "${BACKUP_DIRS[@]}"
if [ $? -eq 0 ]; then
    log "Backup completado con éxito."
else
    log "Error: Backup fallido."
    exit 1
fi

# Verificar integridad del repositorio
restic check
if [ $? -eq 0 ]; then
    log "Verificación completada correctamente."
else
    log "Advertencia: Verificación fallida."
fi

# Limpiar snapshots antiguos según política
restic forget $RETENTION --prune
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente."
else
    log "Advertencia: Error al eliminar snapshots antiguos."
fi

log "=== Backup Restic finalizado ==="    