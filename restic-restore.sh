#!/bin/bash
export RESTIC_REPOSITORY="/mnt/backups/restic-backups"
export RESTIC_PASSWORD="TuContraseñaSegura"
# Carpeta donde se restaura
DEFAULT_TARGET="/tmp/restic-restore"


log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Listar snapshots y asignar números
list_snapshots() {
    echo "=== Snapshots disponibles ==="
    SNAPSHOTS=($(restic snapshots --json | jq -r '.[].short_id'))
    DATES=($(restic snapshots --json | jq -r '.[].time'))

    for i in "${!SNAPSHOTS[@]}"; do
        printf "%2d) ID: %s | Fecha: %s\n" "$((i+1))" "${SNAPSHOTS[$i]}" "${DATES[$i]}"
    done
}

# Requiere jq instalado para parsear JSON
list_snapshots

read -p "Introduce el número o ID del snapshot que quieres restaurar: " CHOICE

# Determinar si es número
if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    INDEX=$((CHOICE-1))
    SNAP_ID=${SNAPSHOTS[$INDEX]}
else
    SNAP_ID="$CHOICE"
fi

echo "¿Dónde quieres restaurar?"
echo "1) En su ruta original (puede sobrescribir archivos)"
echo "2) En carpeta separada ($DEFAULT_TARGET)"
read -p "Elige 1 o 2: " OPTION

if [ "$OPTION" == "1" ]; then
    TARGET="/"
    log "Restaurando snapshot $SNAP_ID en su ruta original..."
else
    TARGET="$DEFAULT_TARGET/$SNAP_ID"
    mkdir -p "$TARGET"
    log "Restaurando snapshot $SNAP_ID en $TARGET..."
fi

# Restaurar snapshot
restic restore "$SNAP_ID" --target "$TARGET"
if [ $? -eq 0 ]; then
    log "Restauración completada con éxito."
else
    log "Error: Fallo en la restauración."
fi