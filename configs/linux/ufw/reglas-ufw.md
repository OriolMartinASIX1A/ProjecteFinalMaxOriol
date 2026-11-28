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

## Cambios del 27/11/2026

- **LNX02:** mismas 15 reglas que LNX01 (orden seguro: LNX02 como secundaria, `pcs status` después).
- **BKP02** (almacenamiento de Bareos y Director en espera):

| Puerto | Servicio | Origen |
|---|---|---|
| 22/tcp | SSH (y `rsync` de `bareos-standby-sync` desde BKP01) | 192.168.200.0/22 |
| 9103/tcp | Almacenamiento de Bareos (trabajo de copia) | 192.168.202.30 |
| 9103/tcp | Almacenamiento de Bareos (**restauración**: el agente conecta directamente) | 192.168.202.28, 192.168.202.29 |

  Las reglas del 9103 desde .28 y .29 se añadieron durante la prueba PR-06: sin ellas, una restauración desde BKP02 se queda esperando (`waiting for Client to connect to Storage daemon`). Cuando haya agentes en las Windows, añadir también .23–.26 en BKP01 y BKP02.

- **Kea DHCP en LNX01 y LNX02** (solo en la tarjeta de la red aislada `ens19`):

```bash
# LNX01 (en LNX02, cambiar 10.10.10.29 por 10.10.10.28 y el comentario)
sudo ufw allow in on ens19 to any port 67 proto udp comment 'DHCP Kea (red aislada vmbr1)'
sudo ufw allow in on ens19 from 10.10.10.29 to any port 8000 proto tcp comment 'Kea HA desde lnx02'
```

  Kea recibe el DHCP con *sockets raw*, que `ufw` no filtra: lo que impide repartir IP en la red del aula es `"interfaces": [ "ens19" ]` en `kea-dhcp4.conf`.

- **Antes de cambiar la red de un nodo del clúster** (`netplan`, `networkctl`): `sudo pcs node standby lnx0X` y, al terminar, `sudo pcs node unstandby lnx0X` (incidencia del 27/11: `networkctl reload` borró la VIP ≈ 3 s).
