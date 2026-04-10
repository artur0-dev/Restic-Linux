#!/bin/bash
source /home/.restic_env

# -------------------------
# CONFIGURACIÓN
# -------------------------
DEFAULT_TARGET="/tmp/restic-restore"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# -------------------------
# SELECCIÓN DE REPOSITORIO
# -------------------------
echo "Selecciona repositorio:"
echo "1) Local"
echo "2) Backblaze B2"
echo "3) Mega"

read -p "Opción: " REPO_CHOICE

case $REPO_CHOICE in
  1)
    export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
    log "Repositorio seleccionado: LOCAL"
    ;;
  2)
    export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_B2"
    log "Repositorio seleccionado: B2"
    ;;
  3)
    export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_MEGA"
    log "Repositorio seleccionado: MEGA"
    ;;
  *)
    echo "Opción inválida"
    exit 1
    ;;
esac

# contraseña
export RESTIC_PASSWORD="$RESTIC_PASSWORD"

# -------------------------
# LISTAR SNAPSHOTS
# -------------------------
echo ""
echo "=== Snapshots disponibles ==="

SNAPSHOTS=($(restic snapshots --json | jq -r '.[].short_id'))
DATES=($(restic snapshots --json | jq -r '.[].time'))

if [ ${#SNAPSHOTS[@]} -eq 0 ]; then
    echo "No hay snapshots disponibles"
    exit 1
fi

for i in "${!SNAPSHOTS[@]}"; do
    printf "%2d) ID: %s | Fecha: %s\n" "$((i+1))" "${SNAPSHOTS[$i]}" "${DATES[$i]}"
done

echo ""

# -------------------------
# SELECCIÓN SNAPSHOT
# -------------------------
read -p "Introduce número o ID del snapshot: " CHOICE

if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    INDEX=$((CHOICE-1))
    SNAP_ID=${SNAPSHOTS[$INDEX]}
else
    SNAP_ID="$CHOICE"
fi

if [ -z "$SNAP_ID" ]; then
    echo "Snapshot inválido"
    exit 1
fi

# -------------------------
# DESTINO
# -------------------------
echo ""
echo "Destino de restauración:"
echo "1) Ruta original (PELIGRO: sobrescribe archivos)"
echo "2) Carpeta segura (/tmp)"

read -p "Opción: " OPTION

if [ "$OPTION" == "1" ]; then
    TARGET="/"
    log "Restaurando snapshot $SNAP_ID en ruta original"
else
    TARGET="$DEFAULT_TARGET/$SNAP_ID"
    mkdir -p "$TARGET"
    log "Restaurando snapshot $SNAP_ID en $TARGET"
fi

# -------------------------
# RESTORE
# -------------------------
echo ""
echo "Restaurando..."

restic restore "$SNAP_ID" --target "$TARGET"

if [ $? -eq 0 ]; then
    log "Restauración completada con éxito"
    echo "OK"
else
    log "ERROR en restauración"
    echo "FALLO"
fi
