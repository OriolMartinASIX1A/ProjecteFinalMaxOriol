# Reglas de `ufw` de los Linux del clúster (26/11/2026)

Entrada denegada por defecto y salida permitida. Aplicado en LNX01 (15 reglas) y BKP01 (13 reglas, sin el 80). LNX02 pendiente (sesión 5).

```bash
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow from 192.168.200.0/22 to any port 22 proto tcp comment 'SSH administracion'
sudo ufw allow 80/tcp comment 'Web'          # solo LNX01 y LNX02
for ip in 192.168.202.28 192.168.202.29 192.168.202.30; do sudo ufw allow from $ip to any port 5405 proto udp comment 'Corosync'; sudo ufw allow from $ip to any port 2224 proto tcp comment 'pcsd'; sudo ufw allow from $ip to any port 5022 proto tcp comment 'AG endpoint'; sudo ufw allow from $ip to any port 1433 proto tcp comment 'SQL Server'; done
sudo ufw show added
sudo ufw enable && sudo ufw status numbered
```

| Puerto | Servicio | Origen |
|---|---|---|
| 22/tcp | SSH (y SFTP) | 192.168.200.0/22 |
| 80/tcp | Web | Cualquiera (LNX01 y LNX02) |
| 5405/udp | Corosync | .28, .29, .30 |
| 2224/tcp | pcsd | .28, .29, .30 |
| 5022/tcp | Endpoint del AG | .28, .29, .30 |
| 1433/tcp | SQL Server | .28, .29, .30 |

Orden seguro: un nodo cada vez, empezando por uno sin la réplica principal, y `sudo pcs status` desde otro nodo después de cada uno.
