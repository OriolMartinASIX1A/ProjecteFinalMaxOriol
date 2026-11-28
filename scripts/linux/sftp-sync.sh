#!/bin/bash
# Version: 1.0
# sftp-sync.sh - Copia /srv/sftp del nodo que tiene la VIP al otro nodo (SFTP-03).
# 27/11/2026 - Max. Lo lanza cron cada minuto en LNX01 y LNX02 (/etc/cron.d/sftp-sync).
# Solo copia el nodo activo (el que tiene la VIP .27): la copia va siempre del activo al pasivo.
# La clave /root/.ssh/sftp_sync solo permite rsync dentro de /srv/sftp del otro nodo (rrsync).
# RPO del SFTP: 1 minuto (riesgo aceptado, decision de Max del 27/11).
VIP="192.168.202.27"
LOG="/var/log/sftp-sync.log"
case "$(hostname)" in
  lnx01) OTRO="192.168.202.29" ;;
  lnx02) OTRO="192.168.202.28" ;;
  *) exit 0 ;;
esac
ip -4 -o addr show | grep -q " ${VIP}/" || exit 0
if ! flock -n /run/sftp-sync.lock rsync -aH --delete -e "ssh -i /root/.ssh/sftp_sync -o BatchMode=yes -o ConnectTimeout=10" /srv/sftp/ "root@${OTRO}:/" 2>>"$LOG"; then
  echo "$(date '+%F %T') ERROR al copiar /srv/sftp a ${OTRO}" >> "$LOG"
fi
