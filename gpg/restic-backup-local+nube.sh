#!/bin/bash

# -------------------------
# CONFIGURACIÓN
# -------------------------
source /home/.restic_env

BACKUP_DIRS=(
    "/var/log/restic"
    "/home/pruebas.txt"
    "/home/ids_mover_a_db.py"
)
LOG_FILE="$LOG_FILE"
METRICS_SCRIPT="/home/restic-analythics.sh"

# Política de retención
RETENTION="--keep-daily 2"

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

restic forget $RETENTION
if [ $? -eq 0 ]; then
    log "Snapshots antiguos eliminados correctamente (LOCAL)."
else
    log "Advertencia: Error al eliminar snapshots antiguos (LOCAL)."
fi

restic -r "$RESTIC_REPOSITORY" prune

if [ $? -eq 0 ]; then
    log "Datos antiguos eliminados correctamente (Nube)."
else
    log "Advertencia: No se pudieron eliminar algunos datos (posible Object Lock)."
fi

# -------------------------
# BACKUP NUBE (Backblaze B2)
#copia inmutable
# -------------------------
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_B2"
export B2_ACCOUNT_ID="$B2_ACCOUNT_ID"       # tu KeyID
export B2_ACCOUNT_KEY="$B2_ACCOUNT_KEY"      # tu Application Key
export RESTIC_PASSWORD="$RESTIC_PASSWORD"
export RESTIC_PASSWORD2="$RESTIC_PASSWORD"
log "=== Iniciando backup NUBE (B2) ==="


# Backup
restic -r "$RESTIC_REPOSITORY_B2" backup "${BACKUP_DIRS[@]}" --quiet
#restic -r "$RESTIC_REPOSITORY_LOCAL" copy --repo2 "$RESTIC_REPOSITORY_B2"

RETVAL_B2=$?

if [ $RETVAL_B2 -eq 0 ]; then
    log "Backup NUBE completado con éxito."
else
    log "Error: Backup NUBE fallido."
    printf "Subject: Error de backup B2\n\nError en los backups B2" | msmtp "$email"
fi

restic -r "$RESTIC_REPOSITORY_B2" forget $RETENTION

if [ $? -eq 0 ]; then
    log "Snapshots antiguos marcados para eliminación (Nube)."
else
    log "Advertencia: Error al aplicar política de retención (Nube)."
fi


# -------------------------
# BACKUP MEGA (nube)
# -------------------------
DATE=$(date +%F)
BACKUP_FILE="/tmp/backup-$DATE.tar.gz"
ENC_FILE="/tmp/backup-$DATE.tar.gz.gpg"

LAST=$(restic -r "$RESTIC_REPOSITORY_LOCAL" snapshots --latest 1 | awk 'NR==3 {print $1}')
restic restore latest --target "$TMP_DIR"
tar -czf "$BACKUP_FILE" -C "$TMP_DIR" .
echo "$GPG_PASS" | gpg --batch --yes --passphrase-fd 0 -c "$BACKUP_FILE"
rclone copy "$ENC_FILE" "$RESTIC_REPOSITORY_MEGA"
rm -rf "$TMP_DIR"
rm -f "$BACKUP_FILE"
rm -f "$ENC_FILE"
RETVAL_MEGA=$?

if [ $RETVAL_MEGA -eq 0 ]; then
    log "Backup MEGA completado con éxito."
else
    log "Error: Backup MEGA fallido."
    printf "Subject: Error de backup MEGA\n\nError en los backups MEGA" | msmtp "$email"
fi

rclone delete "$RESTIC_REPOSITORY_MEGA" --min-age 7d
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
