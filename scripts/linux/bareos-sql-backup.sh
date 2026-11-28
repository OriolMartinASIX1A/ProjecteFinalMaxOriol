#!/bin/bash
# Version: 1.2
# bareos-sql-backup.sh - Copia COPY_ONLY de las bases de datos del AG antes del trabajo de Bareos (BKP-03).
# 27/11/2026 - Max. Lo lanza Bareos (ClientRunBeforeJob) en LNX01 y LNX02.
# Copia en la secundaria sincronizada; si no hay ninguna secundaria sincronizada, copia la principal.
# En el otro nodo borra el .bak antiguo para que Bareos no guarde una copia vieja.
# v1.1: deja de usar sys.fn_hadr_backup_is_preferred_replica. Con la replica de solo configuracion
#       (bkp01, prioridad 50 que no se puede cambiar: error 47112) ninguna replica salia como preferida.
# v1.2 (27/11/2026): anade cibernova_portal (Portal CiberNova). backup_cibernova necesita db_backupoperator en cada BD.
set -u
CRED=/root/.sqlbackup.cred
DIR=/var/opt/mssql/backup
SQLCMD=/opt/mssql-tools18/bin/sqlcmd
BBDD="cibernova_pruebas cibernova_portal"
USUARIO=$(sed -n 1p "$CRED")
export SQLCMDPASSWORD=$(sed -n 2p "$CRED")
for db in $BBDD; do
  CONSULTA="SET NOCOUNT ON; DECLARE @rol nvarchar(60) = (SELECT role_desc FROM sys.dm_hadr_availability_replica_states WHERE is_local = 1); IF @rol = 'SECONDARY' SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states WHERE is_local = 1 AND database_id = DB_ID('$db') AND synchronization_state_desc = 'SYNCHRONIZED') THEN 1 ELSE 0 END; ELSE IF @rol = 'PRIMARY' SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states WHERE is_local = 0 AND database_id = DB_ID('$db') AND synchronization_state_desc = 'SYNCHRONIZED') THEN 0 ELSE 1 END; ELSE SELECT 0;"
  copiar=$($SQLCMD -S localhost -C -U "$USUARIO" -h -1 -W -b -Q "$CONSULTA") || exit 1
  if [ "$copiar" = "1" ]; then
    $SQLCMD -S localhost -C -U "$USUARIO" -b -Q "BACKUP DATABASE [$db] TO DISK = N'$DIR/$db.bak' WITH COPY_ONLY, INIT, CHECKSUM, COMPRESSION" || exit 1
    echo "$(date '+%F %T') $(hostname): copia de $db hecha"
  else
    rm -f "$DIR/$db.bak"
    echo "$(date '+%F %T') $(hostname): $db se copia en el otro nodo"
  fi
done
