#!/bin/bash
# Version: 1.0
# bareos-standby-sync.sh - Copia a BKP02 la configuracion y el catalogo del Director de Bareos (BKP-05).
# 27/11/2026 - Max. Lo lanza cron en BKP01 cada 30 minutos (/etc/cron.d/bareos-standby-sync).
# Director en espera en frio: BKP02 tiene instalados bareos-director y PostgreSQL, pero el Director esta parado
# y deshabilitado. Este script deja en BKP02 (/srv/bareos/standby) lo necesario para activarlo si BKP01 cae:
#   - /etc/bareos completo de BKP01 (configuracion del Director, clientes, pools, calendarios, contrasenas).
#   - Volcado del catalogo (pg_dump de la BD "bareos"), coherente aunque el Director este trabajando.
# No toca la configuracion activa de BKP02: la activacion es manual y sigue el procedimiento del manual de operacion.
# La clave /root/.ssh/standby_sync solo permite rsync dentro de /srv/bareos/standby de BKP02 (rrsync).
set -uo pipefail
DESTINO="192.168.202.31"
LOG="/var/log/bareos-standby-sync.log"
TMP="/var/backups/bareos-standby"
install -d -m 700 "$TMP"
if ! runuser -u postgres -- pg_dump -d bareos | gzip > "$TMP/catalogo-bareos.sql.gz.tmp"; then
  echo "$(date '+%F %T') ERROR en pg_dump del catalogo" >> "$LOG"; exit 1
fi
mv "$TMP/catalogo-bareos.sql.gz.tmp" "$TMP/catalogo-bareos.sql.gz"
date '+%F %T' > "$TMP/ultima-sincronizacion.txt"
if ! flock -n /run/bareos-standby-sync.lock rsync -a --delete -e "ssh -i /root/.ssh/standby_sync -o BatchMode=yes -o ConnectTimeout=10" /etc/bareos "$TMP/catalogo-bareos.sql.gz" "$TMP/ultima-sincronizacion.txt" "root@${DESTINO}:/" 2>>"$LOG"; then
  echo "$(date '+%F %T') ERROR al copiar a ${DESTINO}" >> "$LOG"; exit 1
fi
