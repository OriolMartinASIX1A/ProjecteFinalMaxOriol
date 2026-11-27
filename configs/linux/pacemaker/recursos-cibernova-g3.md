# Recursos y reglas de Pacemaker del clúster `cibernova-g3` (estado al 26/11/2026)

Configuración común a los tres nodos (LNX01, LNX02 y BKP01): se crea una sola vez desde cualquiera de ellos.

```bash
# Fencing (23/11)
sudo pcs stonith create fence-proxmox fence_pve ip=192.168.202.3 username=fence@pve password=... pve_node=PROC vmtype=qemu ssl_insecure=1 pcmk_host_map="lnx01:128;lnx02:129;bkp01:130"

# AG de SQL Server y VIP (24/11)
sudo pcs resource create ag_cluster ocf:mssql:ag ag_name=sqlag_cibernova meta failure-timeout=60s promotable notify=true
sudo pcs resource create virtualip ocf:heartbeat:IPaddr2 ip=192.168.202.27 cidr_netmask=22 op monitor interval=10s
sudo pcs constraint colocation add virtualip with Promoted ag_cluster-clone INFINITY
sudo pcs constraint order promote ag_cluster-clone then start virtualip

# Apache (26/11, opción A: un solo Apache, siempre con la VIP)
sudo pcs resource create apache ocf:heartbeat:apache configfile=/etc/apache2/apache2.conf statusurl="http://localhost/server-status" op monitor interval=20s timeout=20s --disabled
sudo pcs constraint colocation add apache with virtualip INFINITY
sudo pcs constraint order virtualip then apache
sudo pcs constraint location apache avoids bkp01
sudo pcs resource enable apache
```

La contraseña de `fence@pve` no se guarda aquí (`password=...`). Sin preferencia de nodo para la réplica principal (decisión del 26/11).

Conmutación manual (nunca con `ALTER AVAILABILITY GROUP ... FAILOVER`):

```bash
sudo pcs resource move ag_cluster-clone lnx02 --promoted
sudo pcs constraint location     # comprobar que no queda ninguna regla cli-prefer
```
