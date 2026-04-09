#!/bin/bash
# Backup local + nube Backblaze B2
source /home/.restic_env

export RESTIC_PASSWORD="$RESTIC_PASSWORD"
BACKUP_DIRS=("/etc" "/home/ids_mover_a_db.py")
LOG_FILE=~/restic-backup.log

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"; }

#Backup local
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
restic backup "${BACKUP_DIRS[@]}" --quiet
RETVAL_LOCAL=$?

# Guardar métricas para backup local
if [ $RETVAL_LOCAL -eq 0 ]; then
    log "Backup local OK"
    /home/restic-metrics.sh OK
else
    log "Backup local FAIL"
    /home/restic-metrics.sh FAIL
fi

# Backup nube
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY"
export B2_ACCOUNT_ID="$B2_ACCOUNT_ID"
export B2_ACCOUNT_KEY="$B2_ACCOUNT_KEY"
restic backup "${BACKUP_DIRS[@]}"
RETVAL_CLOUD=$?

# Guardar métricas para backup nube
if [ $RETVAL_CLOUD -eq 0 ]; then
    log "Backup nube OK"
    /home/restic-metrics.sh OK
else
    log "Backup nube FAIL"
    /home/restic-metrics.sh FAIL
fi