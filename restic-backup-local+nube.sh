#!/bin/bash
# restic-backup.sh
# Backup automático de archivos de configuración (local + B2)

# -------------------------
# CONFIGURACIÓN
# -------------------------
source /home/.restic_env

BACKUP_DIRS=(
    "/var/log/restic"
    "/home/pruebas.txt"
    "/home/ids_mover_a_db.py"
)
LOG_FILE="/var/log/restic/restic-backup.log"
METRICS_SCRIPT="/home/restic-analythics.sh"

# Política de retención
RETENTION="--keep-daily 7"

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
    printf "Subject: Error de backup LOCAL\n\nError en los backups LOCAL" | msmtp "$email"
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
export RESTIC_PASSWORD2="$RESTIC_PASSWORD"
log "=== Iniciando backup NUBE (B2) ==="


# Copiar el último snapshot
restic -r "$RESTIC_REPOSITORY_LOCAL" copy --repo2 "$RESTIC_REPOSITORY_B2"

RETVAL_B2=$?

if [ $RETVAL_B2 -eq 0 ]; then
    log "Backup NUBE completado con éxito."
else
    log "Error: Backup NUBE fallido."
    printf "Subject: Error de backup B2\n\nError en los backups B2" | msmtp "$email"
fi

restic -r "$RESTIC_REPOSITORY_B2" forget $RETENTION --prune
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente (Nube)."
else
    log "Advertencia: Error al eliminar snapshots antiguos (Nube)."
fi

# -------------------------
# BACKUP MEGA (nube)
# -------------------------

rclone sync "$RESTIC_REPOSITORY_LOCAL" mega-restic:restic-backups
RETVAL_MEGA=$?

if [ $RETVAL_MEGA -eq 0 ]; then
    log "Backup MEGA completado con éxito."
else
    log "Error: Backup MEGA fallido."
    printf "Subject: Error de backup MEGA\n\nError en los backups MEGA" | msmtp "$email"
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
