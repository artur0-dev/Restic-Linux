===================================================
      SISTEMA DE BACKUP CON RESTIC
      LOCAL + NUBE BACKBLAZE B2
===================================================

Este sistema permite:

1. Hacer backups locales en tu disco.
2. Hacer backups en la nube (Backblaze B2).
3. Mantener un historial de 14 días.
4. Registrar métricas en SQLite para visualización en Grafana.
5. Restaurar archivos fácilmente.

-----------------------------------------------------
1️⃣ PREPARAR BACKUPS LOCALES
-----------------------------------------------------

1. Crear carpeta para los backups:
   mkdir -p /mnt/backups/restic-backups

2. Crear carpeta para logs:
   mkdir -p /var/log/restic

3. Crear archivo de variables .env:
   nano /home/.restic_env

   Ejemplo de contenido:
   # Repositorios
   RESTIC_REPOSITORY_LOCAL=/mnt/backups/restic-backups
   RESTIC_REPOSITORY_B2=b2:mi-backup-pruebas-seccion9-2026

   # Credenciales
   RESTIC_PASSWORD="TuContraseñaSegura"
   B2_ACCOUNT_ID="tu_account_id"
   B2_ACCOUNT_KEY="tu_application_key"

4. Inicializar el repositorio (solo la primera vez):
   restic init

5. Verificar que Restic está instalado:
   restic version

-----------------------------------------------------
2️⃣ SCRIPT DE BACKUP LOCAL
-----------------------------------------------------

Archivo: restic-backup.sh

- Este script:
  - Hace backup de las carpetas indicadas.
  - Verifica integridad del repositorio.
  - Elimina snapshots antiguos según política (máx 14 días).
  - Guarda logs en /var/log/restic/restic-backup.log
  - Dar permisos de ejecución:
    chmod +x /home/restic-backup.sh

-----------------------------------------------------
3️⃣ PROGRAMAR BACKUPS AUTOMÁTICOS
-----------------------------------------------------

- Editar crontab:
  crontab -e

- Agregar backup todos los dias a las 12:
  0 0 * * * /bin/bash /home/restic-backup.sh

-----------------------------------------------------
4️⃣ RESTAURACIÓN DE BACKUPS
-----------------------------------------------------

- Ver snapshots disponibles:
  restic snapshots

- Restaurar en carpeta temporal:
  restic restore <ID_DEL_SNAPSHOT> --target /tmp/restic-restore

- Restaurar en la ruta original (sobrescribe archivos):
  restic restore <ID_DEL_SNAPSHOT> --target /

- También se puede usar el script interactivo de restauración, que permite elegir snapshot y carpeta destino:
   ./restic-restore.sh

-----------------------------------------------------
5️⃣ BACKUP EN LA NUBE BACKBLAZE B2
-----------------------------------------------------

1. Definir conexión a B2 y contraseña en el .env:
   export RESTIC_REPOSITORY=b2:mi-backup-pruebas-seccion9-2026
   export B2_ACCOUNT_ID="tu_account_id"
   export B2_ACCOUNT_KEY="tu_application_key"
   export RESTIC_PASSWORD="TuContraseñaSegura"

2. Inicializar repositorio en B2 (solo una vez):
   restic init

3. Script de backup local + nube (restic-backup-local+nube.sh):



-----------------------------------------------------
6️⃣ MÉTRICAS Y MONITOREO
-----------------------------------------------------

- El script restic-metrics.sh guarda:
  - snapshot_id
  - fecha y hora
  - número de archivos
  - tamaño total
  - host
  - estado del backup (OK/FAIL)
- Guardado en SQLite para visualización en Grafana.

-----------------------------------------------------
7️⃣ RESUMEN DE PASOS
-----------------------------------------------------

1. Crear carpetas de backup y logs.
2. Instalar Restic.
3. Configurar variables de entorno.
4. Inicializar repositorios (local y B2).
5. Crear scripts de backup y métricas.
6. Programar cron para automatizar backups.
7. Restaurar snapshots cuando sea necesario.
8. Monitorear métricas y estado de los backups.

-----------------------------------------------------
FIN DEL MANUAL
-----------------------------------------------------