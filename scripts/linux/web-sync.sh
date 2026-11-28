#!/bin/bash
# Version: 1.0
# web-sync.sh - Copia /var/www/html del nodo que tiene la VIP al otro nodo (WEB-03).
# 27/11/2026 - Max. Lo lanza cron cada minuto en LNX01 y LNX02 (/etc/cron.d/web-sync).
# Mismo diseno que sftp-sync.sh: solo copia el nodo activo (el que tiene la VIP .27), del activo al pasivo.
# La clave /root/.ssh/web_sync solo permite rsync dentro de /var/www/html del otro nodo (rrsync).
# Los cambios de la web se hacen SIEMPRE en el nodo activo: lo que se cambie en el pasivo se pierde en 1 minuto.
# /etc/cibernova/web.ini (credenciales) NO se copia: esta fuera de la carpeta web y se mantiene a mano.
VIP="192.168.202.27"
LOG="/var/log/web-sync.log"
case "$(hostname)" in
  lnx01) OTRO="192.168.202.29" ;;
  lnx02) OTRO="192.168.202.28" ;;
  *) exit 0 ;;
esac
ip -4 -o addr show | grep -q " ${VIP}/" || exit 0
if ! flock -n /run/web-sync.lock rsync -a --delete -e "ssh -i /root/.ssh/web_sync -o BatchMode=yes -o ConnectTimeout=10" /var/www/html/ "root@${OTRO}:/" 2>>"$LOG"; then
  echo "$(date '+%F %T') ERROR al copiar /var/www/html a ${OTRO}" >> "$LOG"
fi
