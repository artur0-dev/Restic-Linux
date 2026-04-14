#!/bin/bash
source /home/.restic_env

DEFAULT_TARGET="/tmp/restic-restore"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

TMP_MEGA="/tmp/restore-mega"

# -------------------------
# SELECCIÓN REPOSITORIO
# -------------------------
echo "Selecciona repositorio:"
echo "1) Local (Restic)"
echo "2) Backblaze B2 (Restic)"
echo "3) Mega (archivos cifrados)"

read -p "Opción: " REPO_CHOICE

# =========================================================
# MEGA RESTORE
# =========================================================
if [ "$REPO_CHOICE" == "3" ]; then

    echo ""
    echo "=== BACKUPS EN MEGA ==="

    FILES=($(rclone lsf "$RESTIC_REPOSITORY_MEGA" | grep ".gpg"))

    if [ ${#FILES[@]} -eq 0 ]; then
        echo "No hay backups en MEGA"
        exit 1
    fi
     for i in "${!FILES[@]}"; do
        echo "$((i+1))) ${FILES[$i]}"
    done

    echo ""
    read -p "Elige backup: " CHOICE

    INDEX=$((CHOICE-1))
    FILE="${FILES[$INDEX]}"

    if [ -z "$FILE" ]; then
        echo "Selección inválida"
        exit 1
    fi

    mkdir -p "$TMP_MEGA"

    log "Descargando backup MEGA..."
    rclone copy "mega-restic:restic-backups/$FILE" "$TMP_MEGA/"

    log "Desencriptando..."
    gpg --batch --yes --passphrase "$GPG_PASS" \
        -o "$TMP_MEGA/backup.tar.gz" \
        -d "$TMP_MEGA/$FILE"

    echo ""
    echo "Destino:"
    echo "1) Sistema original (/)"
    echo "2) Carpeta segura (/tmp/restore)"

    read -p "Opción: " OPT

    if [ "$OPT" == "1" ]; then
        TARGET="/"
        log "Restaurando en sistema original"
    else
        TARGET="/tmp/restore"
        mkdir -p "$TARGET"
        log "Restaurando en $TARGET"
    fi

    log "Extrayendo backup..."
    tar -xzf "$TMP_MEGA/backup.tar.gz" -C "$TARGET"

    log "RESTORE MEGA COMPLETADO"

    rm -rf "$TMP_MEGA"
     exit 0
fi

# =========================================================
# RESTIC (LOCAL / B2)
# =========================================================

case $REPO_CHOICE in
  1)
    export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_LOCAL"
    log "Repositorio LOCAL seleccionado"
    ;;
  2)
    export RESTIC_REPOSITORY="$RESTIC_REPOSITORY_B2"
    log "Repositorio B2 seleccionado"
    ;;
  *)
    echo "Opción inválida"
    exit 1
    ;;
esac

export RESTIC_PASSWORD="$RESTIC_PASSWORD"

echo ""
echo "=== Snapshots disponibles ==="

SNAPSHOTS=($(restic snapshots --json | jq -r '.[].short_id'))
DATES=($(restic snapshots --json | jq -r '.[].time'))

if [ ${#SNAPSHOTS[@]} -eq 0 ]; then
    echo "No hay snapshots"
    exit 1
fi

for i in "${!SNAPSHOTS[@]}"; do
    printf "%2d) %s | %s\n" "$((i+1))" "${SNAPSHOTS[$i]}" "${DATES[$i]}"
done

echo ""
read -p "Elige snapshot (número o ID): " CHOICE

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

echo ""
echo "Destino:"
echo "1) Sistema original (/)"
echo "2) Carpeta segura (/tmp)"

read -p "Opción: " OPT

if [ "$OPT" == "1" ]; then
    TARGET="/"
    log "Restaurando snapshot $SNAP_ID en /"
else
    TARGET="$DEFAULT_TARGET/$SNAP_ID"
    mkdir -p "$TARGET"
    log "Restaurando en $TARGET"
fi

log "Restaurando snapshot..."

restic restore "$SNAP_ID" --target "$TARGET"

if [ $? -eq 0 ]; then
    log "RESTORE COMPLETADO"
else
    log "ERROR EN RESTORE"
    exit 1
fi