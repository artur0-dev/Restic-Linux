#!/bin/bash
source /home/.restic_env
export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
export RESTIC_PASSWORD="$RESTIC_PASSWORD"
LOG_FILE="/var/log/restic/restic_restore_test.log"
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "=== Probando restauración ==="
restic restore latest --target /tmp/test_restore

if [ $? -eq 0 ]; then
    log "Restauración de prueba completada."
    rm -rf /tmp/test_restore
    log "Carpeta de prueba eliminada."
else
    log "ERROR: la restauración de prueba falló."
fi