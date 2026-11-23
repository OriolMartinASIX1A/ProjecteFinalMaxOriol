# Memoria técnica de la infraestructura desplegada – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Versión:** 0.10 · 23/11/2026 (clúster Pacemaker de 3 nodos y fencing, apartado 2.3.7) · v0.9 · 19/11/2026 (sesión 2 Linux: SQL Server configurado, BKP01 y BKP02, apartado 2.3.6) · v0.8 · 19/11/2026 (DC02 promovido; reenviadores de DC02, apartado 3.3) · v0.7 · 19/11/2026 (DC02 en VirtualBox, apartado 2.4) · v0.6 · 19/11/2026 (reenviadores corregidos a 8.8.8.8 y 1.1.1.1; scripts 04 y 93 v1.2) · v0.5 · 18/11/2026 (sesión 1 y DNS/GPO de DC01)

> Documento vivo: se amplía al terminar cada servicio. Lo marcado con **[PENDIENTE DE CONFIRMAR]** hay que verificarlo.

---

## 1. Estado actual (19/11/2026)

| VM | Estado | Dónde está | Notas |
|---|---|---|---|
| Host Proxmox | Instalado (Proxmox VE 9.2.21, nodo `PROC`) | Servidor físico (192.168.202.3) | Ver [guía del hipervisor](02-guia-instalacion-hipervisor.md) |
| DC01 | **AD completo** (16/11): bosque `cibernova.local`, 23 OU, 27 grupos, 89 empleados, 6 cuentas adm., 6 cuentas especiales y políticas de contraseña. **DNS configurado y verificado** (18/11, apartado 3.3) y **GPO de seguridad** (18/11, apartado 3.4). Hora con `hora.roa.es`. **No se importó el 17/11 (D-05).** Faltan los grupos `DL_` y la unión del resto de máquinas | **VirtualBox** (exportar a OVA e importar en Proxmox en la sesión 2) | |
| DC02 | **Promovido el 19/11 en VirtualBox** (DNS + catálogo global), replicando con DC01 | Pendiente de exportar a OVA e importar en Proxmox (VMID 124) junto con DC01 | Ver precauciones del apartado 2.4 y [guía 07](07-guia-dominio-dc02-union.md), apartado 2 |
| LNX01 | **Proxmox (VMID 128)**: Ubuntu 24.04.5, IP .28 fija, DNS públicos, **SQL Server 2025 Enterprise Developer** con Always On y Agente | **Proxmox** | Importación manual (el asistente falló). Apartados 2.3 y 2.3.6 |
| LNX02 | **Proxmox (VMID 129)**: clon de LNX01 personalizado, IP .29, **SQL Server 2025 Enterprise Developer** con Always On y Agente | Proxmox | Apartados 2.3.4 y 2.3.6 |
| BKP01 | **Proxmox (VMID 130)**: clon personalizado (18/11), IP .30, **SQL Server 2025 Express** con Always On (futura réplica de solo configuración) | Proxmox | Apartados 2.3.4 y 2.3.6 |
| BKP02 | **Proxmox (VMID 131)**: clon de la instantánea `base-limpia` (sin SQL Server), personalizado, IP .31 | Proxmox | Apartado 2.3.6. Bareos pendiente |
| FS01, FS02, clientes | Sin crear | — | — |

> **Lista de todo lo pendiente** (requisitos del enunciado y del Anexo I, con su estado): [`docs/gestion/lista-tareas-fase1.md`](../gestion/lista-tareas-fase1.md).

---

## 2. Método de construcción

### 2.1 Decisión: Windows en VirtualBox → OVA → Proxmox

Con la primera versión de Proxmox no se podía instalar Windows Server, y tras reinstalarlo con la versión 9.2.21 las VMs Windows en Proxmox iban **tan lentas que no se podía trabajar** (no daba un error concreto).

En ese primer intento en Proxmox se llegó a promover un DC01 y DC01 y DC02 se veían entre sí (ping correcto), pero DC02 no se pudo unir al dominio por la lentitud, el dominio empezó a dejar de responder y no se podía iniciar sesión. Se eliminaron esas máquinas, se probó a exportar una OVA desde VirtualBox e importarla (funcionó) y se empezó de nuevo con las máquinas en VirtualBox. Por eso:

- Las máquinas **Windows** se crean en **VirtualBox** (en los ordenadores del equipo), se exportan como **OVA** y se importan en Proxmox.
- Las máquinas **Ubuntu** ya están creadas **en Proxmox**.

**Ventajas:** se puede trabajar fuera del horario del aula (los servidores solo se encienden en las sesiones) y sin depender del rendimiento del host.

**Inconvenientes y riesgos:**
- Al importar cambia el hardware virtual (controlador de disco y tarjeta de red): Windows puede no arrancar si el disco pasa a VirtIO sin drivers, y la configuración IP se queda en la tarjeta antigua.
- Los controladores de dominio son delicados de mover (apartado 2.4).
- Si las VMs Windows ya iban lentas en Proxmox, **también pueden ir lentas después de importarlas**. Las causas probables y cómo comprobarlas están en la [guía del hipervisor, apartado 9](02-guia-instalacion-hipervisor.md#9-rendimiento-de-las-vms-windows). Hay que mirarlo en la primera importación.

### 2.2 Procedimiento de importación en Proxmox (propuesto)

> Pendiente de probar en la primera importación. Se documentará el resultado real.

1. **En VirtualBox:** apagar la VM por completo (no suspender) → *Archivo → Exportar servicio virtualizado* → formato OVF 2.0 → fichero `.ova`.
2. **En Proxmox:** habilitar la importación en un almacenamiento de tipo directorio: *Datacenter → Storage → local → Edit → Content* → marcar **Import**.
3. Subir el `.ova`: *local → Import → Upload*.
4. Seleccionar el `.ova` → **Import**:
   - Almacenamiento de destino: `local-lvm`.
   - **Disco: SATA** (Windows lo reconoce sin drivers extra).
   - **Red: Intel E1000** en `vmbr0` (Windows tiene el driver integrado).
5. Arrancar la VM y, en Windows:
   - Comprobar que la nueva tarjeta tiene la **IP fija** (la configuración se queda en la tarjeta antigua de VirtualBox): IP, máscara **255.255.252.0**, puerta de enlace 192.168.200.254 y DNS.
   - Comprobar el acceso con `ping` a la puerta de enlace y al otro DC.
6. Recomendado: instalar los drivers VirtIO y el agente de QEMU (`virtio-win.iso`) y después pasar disco y red a VirtIO (mejora mucho el rendimiento).

**Capturas:** exportación en VirtualBox, asistente de importación en Proxmox, `ipconfig /all` tras importar, ping.

### 2.3 LNX01: instalación limpia en VirtualBox (17/11/2026)

La VM "WEB01" de Proxmox (de un inicio de proyecto anterior) **no tenía Ubuntu 24.04**, que es la versión que necesita SQL Server 2025. Se descartó adaptarla y LNX01 se instaló de cero en VirtualBox, con el mismo método que Windows (desfase D-03 en la bitácora).

| Alternativa | Decisión | Motivo |
|---|---|---|
| Actualizar WEB01 con `do-release-upgrade` | Descartada | Arrastra restos del proyecto anterior y es más difícil de justificar |
| Reinstalar directamente en Proxmox | Descartada | Con las máquinas de Proxmox solo se puede trabajar en horario de clase |
| **Instalar en VirtualBox en casa → OVA → Proxmox** | **Elegida** | Aprovecha el tiempo fuera de horario y es el mismo método que Windows (D-01) |

#### 2.3.1 Hecho en VirtualBox

| Parámetro | Valor |
|---|---|
| ISO | `ubuntu-24.04.5-live-server-amd64.iso` |
| Recursos en VirtualBox | 2 vCPU, 4 GB de RAM, disco dinámico de 60 GB, BIOS (sin EFI), red NAT |
| Instalación | Ubuntu Server, disco entero con LVM, hostname `lnx01`, usuario `admincibernova`, OpenSSH, sin snaps |

Comandos ejecutados después de instalar:

```bash
lsb_release -a                       # Ubuntu 24.04.5 LTS (noble)

# El instalador solo asigna al volumen raíz la mitad del grupo de volúmenes (29 de 58 GB)
df -h / ; sudo vgs ; lsblk
sudo lvextend -r -l 100%VG /dev/ubuntu-vg/ubuntu-lv   # -r amplía también el ext4, en caliente
df -h /                              # 57 GB

sudo apt update && sudo apt full-upgrade -y
sudo apt install -y qemu-guest-agent # en VirtualBox no arranca (normal); en Proxmox sí
sudo timedatectl set-timezone Europe/Madrid

# Que cloud-init no reescriba la red al cambiar la tarjeta en Proxmox
sudo nano /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
#   network:
#     config: disabled

sudo reboot
hostnamectl ; timedatectl ; ip -br link ; ip -br addr   # lnx01, Europe/Madrid, enp0s3
```

Exportación: *Archivo → Exportar servicio virtualizado* → OVF 2.0 → **Quitar todas las direcciones MAC** → `LNX01.ova`. Exportar a un disco distinto del que contiene la VM: leer y escribir en el mismo USB lo hace muy lento.

**Capturas** (en `E:\LNX01`): `lsb-release`, `disco-antes`, `disco-ampliado`, `apt-upgrade`, `qemu-agent-zona-horaria`, `cloud-init-red-desactivada`, `cloud-init-fichero`, `hostname-hora-red` (prefijo `2026-11-17_sesion01_lnx01_`).

**No actualizar a Ubuntu 26.04** aunque el sistema lo ofrezca al iniciar sesión: SQL Server 2025 necesita 24.04.

#### 2.3.2 Importación en Proxmox (hecha el 17/11, sesión 1)

1. Activar la importación: *Datacenter → Storage → local → Edit → Content* → **Import**.
2. Subir la OVA por la web: *PROC → local → Import → Upload* (1,81 GiB; *Hash algorithm*: **None**). La alternativa es `scp LNX01.ova root@192.168.202.3:/var/lib/vz/import/`.
3. El asistente (*local → Import → LNX01.ova → Import*) **falló** con `OVF parser terminated unexpectedly trying to parse /var/lib/vz/import/LNX01.ova (500)`. La OVA estaba bien: `tar -tvf` lista `LNX01.ovf`, `LNX01.mf` y `LNX01-disk001.vmdk`. El problema es el lector de OVF de Proxmox con la OVA de VirtualBox.
4. **Importación manual** (crear la VM y convertir el disco):

```bash
cd /var/lib/vz/import
mkdir -p lnx01 && tar -xvf LNX01.ova -C lnx01
qm create 128 --name LNX01 --ostype l26 --cores 2 --cpu host --memory 4096 --scsihw virtio-scsi-single --net0 virtio,bridge=vmbr0 --agent enabled=1
qm importdisk 128 lnx01/LNX01-disk001.vmdk local-lvm
qm set 128 --scsi0 local-lvm:vm-128-disk-0,iothread=1 --boot order=scsi0
qm config 128
```

Cada comando en **una sola línea**: al pegar la versión partida con `\` dio `400 too many arguments`.

Resultado (`qm config 128`): `agent: enabled=1`, `boot: order=scsi0`, `cores: 2`, `cpu: host`, `memory: 4096`, `net0: virtio,bridge=vmbr0`, `ostype: l26`, `scsi0: local-lvm:vm-128-disk-0,iothread=1,size=60G`, `scsihw: virtio-scsi-single`. Firmware: SeaBIOS (por defecto, igual que en VirtualBox).

5. Antes de arrancar, comprobar que nadie usa la .28: `ping -c 2 192.168.202.28` (no debe responder).
6. Al arrancar, la tarjeta se llama `ens18` y queda **DOWN**, porque el netplan aún tiene `enp0s3`. Prueba con una IP temporal (se pierde al reiniciar; cada comando con `sudo`):

```bash
sudo ip link set ens18 up
sudo ip addr add 192.168.202.28/22 dev ens18
sudo ip route add default via 192.168.200.254
ping -c 3 192.168.200.254     # OK
```

Resultado: puerta de enlace e **Internet accesibles desde la .28** (17/11).

7. IP fija con netplan, por SSH (`ssh admincibernova@192.168.202.28`), porque en la consola noVNC no se puede pegar. **Hecho el 17/11**: aguanta el reinicio y el *Summary* de Proxmox muestra la IP (agente QEMU). El fichero final usa DNS públicos (apartado 2.3.3):

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 192.168.202.28/22
      routes:
        - to: default
          via: 192.168.200.254
      nameservers:
        # Mientras DC01 y DC02 no esten en Proxmox, usar solo 192.168.200.254.
        # Cuando esten, cambiar a: [192.168.202.23, 192.168.202.24]
        addresses: [8.8.8.8, 1.1.1.1]
        search: [cibernova.local]
```

```bash
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan try             # ENTER para confirmar; si se corta, se deshace en 120 s
ip -br addr ; ip route ; ping -c 3 192.168.200.254
sudo reboot                  # comprobar que vuelve con la IP fija
```

8. Liberar espacio en `local` cuando LNX01 funcione: `rm -r /var/lib/vz/import/lnx01 /var/lib/vz/import/LNX01.ova`.

**Consola con copiar y pegar (propuesta):** añadir un puerto serie (`qm set 128 --serial0 socket`) y, dentro de Ubuntu, `sudo systemctl enable --now serial-getty@ttyS0.service`. Después, *Console → xterm.js*.

**Capturas:** `proxmox_storage-import-activado`, `lnx01_subida-ova`, `lnx01_tar-ova`, `lnx01_importdisk`, `lnx01_qm-config`, `lnx01_ip-temporal-ping`, y cuando esté hecho `lnx01_netplan`, `lnx01_ip-br-addr`, `lnx01_summary-ip-agente`, `lnx01_ssh`.

### 2.3.3 DNS del aula: no responde (17/11)

`curl https://packages.microsoft.com/...` falló con `Could not resolve host`. Diagnóstico:

```bash
resolvectl status ens18                       # DNS: 192.168.200.254
ping -c 2 8.8.8.8                             # OK: hay Internet
resolvectl query packages.microsoft.com       # se queda colgado: el DNS del aula no responde
sudo resolvectl dns ens18 8.8.8.8 1.1.1.1     # prueba temporal
resolvectl query packages.microsoft.com       # OK
```

**Conclusión:** el router del aula da salida a Internet al rango .23–.33, pero **no contesta a las consultas DNS**. Es la misma causa del FAIL del reenviador en el `dcdiag` de DC01. **Solución:** `nameservers: addresses: [8.8.8.8, 1.1.1.1]` en netplan (sin 192.168.200.254: si se deja el primero, cada consulta espera varios segundos). Cuando DC01/DC02 estén en Proxmox, los Linux pasan a .23/.24 y los DC reenvían a **8.8.8.8 y 1.1.1.1** (decidido el 18/11; el 18/11 se comprobó además que la red del aula **intercepta el DNS**, apartado 3.3).

### 2.3.4 SQL Server 2025 en LNX01 y clones LNX02/BKP01 (17/11, opción A)

**Paquetes** (guía oficial de Microsoft para Ubuntu 24.04; cada comando en una línea):

```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list | sudo tee /etc/apt/sources.list.d/mssql-server-2025.list
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo apt-get install -y mssql-server mssql-server-ha
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && source ~/.bashrc
dpkg -l | grep -E "mssql|msodbc"
```

Instalado: `mssql-server` y `mssql-server-ha` **17.0.5065.9-3**, `mssql-tools18` y `msodbcsql18` 18.7.1.1-1. `mssql-server-ha` es el agente que permite a Pacemaker gestionar el AG. **No se ejecutó `mssql-conf setup`**: al configurarlo, SQL Server guarda el nombre del equipo, y los clones se llamarían `lnx01` por dentro.

**Clones (decisión de Max, opción A):**

| Alternativa | Ventaja | Inconveniente | Decisión |
|---|---|---|---|
| **A. Clonar LNX01 en Proxmox y personalizar** | Unos 10 min por VM, con Ubuntu actualizado y SQL Server instalado | Hay que regenerar los identificadores | **Elegida** |
| B. Instalar cada VM en VirtualBox (opción mixta) | Instalaciones independientes | Una tarde por VM y otra OVA que importar | Descartada (tiempo; cierre el 4/12) |

Clonar un Linux es seguro (a diferencia de un DC) si cada clon tiene identificadores propios:

```bash
# Proxmox
qm snapshot 128 base-limpia --description "Ubuntu 24.04.5 actualizado, IP .28, antes de SQL Server"
qm clone 128 129 --name LNX02 --full 1
qm clone 128 130 --name BKP01 --full 1
qm shutdown 128 && qm start 129      # el clon arranca con la .28: LNX01 apagada
```

```bash
# Dentro del clon (por SSH a la .28; antes, en el portatil: ssh-keygen -R 192.168.202.28)
sudo hostnamectl set-hostname lnx02
sudo sed -i 's/lnx01/lnx02/g' /etc/hosts
sudo rm -f /etc/machine-id /var/lib/dbus/machine-id && sudo systemd-machine-id-setup && sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id
sudo rm -f /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server
sudo sed -i 's#192.168.202.28/22#192.168.202.29/22#' /etc/netplan/50-cloud-init.yaml
sudo reboot
# Comprobacion: ssh a la .29 -> hostnamectl, cat /etc/machine-id, ip -br addr, cat /etc/hosts
```

- **`machine-id`**: identificador único de cada Linux; lo usan systemd, Corosync y SSSD. Repetido causa fallos difíciles de diagnosticar.
- **Claves SSH de host**: identifican al servidor ante los clientes; repetidas, no se distingue una máquina de otra.

Estado el 17/11: **LNX02 personalizada** (`machine-id` 95ec319c…, IP .29). BKP01 clonada; **personalizada el 18/11** con el mismo procedimiento (`bkp01`, IP .30). Los clones completos ocupan el disco entero en el thin pool (`Data% 100`); propuesta: `discard=on` y `fstrim -av` **[PENDIENTE DE CONFIRMAR]**.

**Capturas:** `lnx01_repos-microsoft`, `lnx01_mssql-instalado`, `proxmox_qm-list-lvs-clones`, `lnx02_personalizado`, `lnx01_history`, `proxmox_history-1/2`.

### 2.3.5 Opción mixta para las VMs Linux (decidida por Max, 17/11)

| Alternativa | Ventaja | Inconveniente | Decisión |
|---|---|---|---|
| Todo en Proxmox, en clase | Una sola copia de cada máquina | Gasta las sesiones en instalaciones | Descartada |
| **Mixta**: paquetes y configuración local en VirtualBox (casa); red, clúster, AG, `fence_pve`, Kea HA y dominio en Proxmox | Las sesiones se dedican a lo que solo se puede hacer allí | Una exportación e importación por máquina | **Elegida** |
| Todo en VirtualBox, incluido el clúster | Se ensaya todo en casa | Simular la red con las IPs reales, sin `fence_pve`, y repetir parte en Proxmox | Descartada |

Regla: **en cuanto una VM se importa, la de Proxmox es la buena**; la copia de VirtualBox no se vuelve a tocar.

### 2.3.6 Sesión 2 (19/11): configuración de SQL Server y BKP02

**Configuración inicial de SQL Server** (en cada máquina, ya con su nombre definitivo; la contraseña de `sa` no se guarda en ningún documento):

```bash
sudo /opt/mssql/bin/mssql-conf setup
sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
sudo systemctl restart mssql-server
```

| Máquina | Edición (opción) | Always On | Agente | Motivo |
|---|---|---|---|---|
| LNX01, LNX02 | **Enterprise Developer** (2) | Sí | Sí | Gratuita con todas las funciones de Enterprise, incluido el AG con conmutación automática. Licencia solo para desarrollo y pruebas (laboratorio); en producción, Enterprise |
| BKP01 | **Express** (4) | Sí | No (Express no lo incluye) | Solo será réplica de solo configuración: no guarda datos, aporta el tercer voto. Edición gratuita y ligera (unos 128 MB de memoria frente a 214 MB) |

Comprobación (necesita el PATH de las herramientas, que faltaba desde el 17/11):

```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && source ~/.bashrc
systemctl status mssql-server --no-pager
sqlcmd -S localhost -U sa -C -W -Q "SELECT @@SERVERNAME AS servidor, SERVERPROPERTY('Edition') AS edicion, SERVERPROPERTY('IsHadrEnabled') AS alwayson"
```

Resultado: cada servidor devuelve su propio nombre (`lnx01`, `lnx02`, `bkp01`), la edición prevista y `alwayson = 1`. `-W` quita los espacios de relleno de las columnas.

**BKP02 desde la instantánea `base-limpia`:**

| Alternativa | Ventaja | Inconveniente | Decisión |
|---|---|---|---|
| Clonar LNX01 actual y desinstalar SQL Server | Parte de la máquina más reciente | Deja restos (`/var/opt/mssql`, repositorios, usuario `mssql`) y más pasos | Descartada |
| **Clonar la instantánea `base-limpia`** (anterior a SQL Server) | Solo el software necesario (menos superficie de ataque), sin pasos extra | Hay que actualizar lo acumulado desde el 17/11 | **Elegida** |
| Instalación limpia en VirtualBox | Independiente de LNX01 | Una tarde y otra OVA | Descartada (tiempo) |

```bash
# Proxmox (LNX01 apagada: el clon arranca con la .28)
qm clone 128 131 --name BKP02 --full 1 --snapname base-limpia
qm start 131
# Dentro: mismo procedimiento del apartado 2.3.4 con bkp02 y 192.168.202.31
# Comprobacion: dpkg -l | grep -i mssql (vacío) y systemctl status mssql-server (no existe)
```

**Actualización:** BKP02 quedó con un kernel más nuevo (6.8.0-151). Se actualizaron las otras tres (`sudo apt update && sudo apt full-upgrade -y && sudo reboot`) para que los cuatro nodos tengan el mismo software, y se comprobó que `mssql-server` arranca solo tras el reinicio.

**Capturas** (prefijo `2026-11-19_sesion02_`): `lnx01_mssql-ediciones`; `lnx01/lnx02/bkp01_mssql-status` y `_mssql-comprobacion`; `proxmox_snapshot-base-limpia`, `proxmox_clon-bkp02`, `proxmox_qm-list-bkp02`; `bkp02_personalizado`, `bkp02_sin-sqlserver`; `bkp02_kernel` y `lnx01/lnx02/bkp01_kernel-mssql`. Captura de BKP01 del 18/11: `2026-11-18_sesion01_bkp01_personalizado`.

### 2.3.7 Clúster Pacemaker + Corosync y fencing (23/11, fuera de horario)

**Decisión: 3 nodos (LNX01, LNX02, BKP01), sin qdevice.**

| Alternativa | Ventaja | Inconveniente | Decisión |
|---|---|---|---|
| **3 nodos Pacemaker** (BKP01 nodo y réplica de solo configuración) | Esquema documentado por Microsoft para el AG en Linux; BKP01 da el tercer voto | BKP01 necesita restricciones para no alojar la VIP ni Apache | **Elegida** |
| 2 nodos + qdevice en BKP01 (lo que decía el diseño) | — | No es posible: la réplica de solo configuración tiene que estar en un nodo del clúster, y el qdevice fuera de él | Descartada |
| 2 nodos + qdevice en BKP02 | Quórum sin tocar BKP01 | BKP01 fuera del clúster: la réplica de solo configuración pierde sentido; fuera del esquema oficial | Descartada |

**Preparación (en los tres nodos):**

```bash
# Nombre del nodo -> IP real (Ubuntu pone "127.0.1.1 <nombre>", que haria escuchar a Corosync en el bucle local)
sudo sed -i '/127.0.1.1/d' /etc/hosts && printf '192.168.202.28 lnx01\n192.168.202.29 lnx02\n192.168.202.30 bkp01\n192.168.202.31 bkp02\n' | sudo tee -a /etc/hosts
getent hosts lnx01 lnx02 bkp01 bkp02 && timedatectl
sudo apt update && sudo apt install -y pacemaker pcs fence-agents-pve
ls /usr/sbin/fence_pve /usr/lib/ocf/resource.d/heartbeat/IPaddr2 && systemctl is-active pcsd
sudo passwd hacluster            # misma contraseña en los tres; no se guarda en ningun documento
sudo pcs cluster destroy         # borra el cluster de ejemplo "debian" que crea Ubuntu
```

**Creación (solo desde LNX01):**

```bash
sudo pcs host auth lnx01 lnx02 bkp01 -u hacluster
sudo pcs cluster setup cibernova-g3 lnx01 addr=192.168.202.28 lnx02 addr=192.168.202.29 bkp01 addr=192.168.202.30
sudo pcs cluster start --all && sudo pcs cluster enable --all
sudo pcs status
sudo corosync-quorumtool -s
```

Transporte **knet** (por defecto): unicast y cifrado con las claves que reparte `pcs`, para no interferir con otros grupos de la red compartida del aula. Resultado: 3 nodos `Online`, 3 votos, quórum 2, `Quorate: Yes` (el clúster sigue si cae cualquier nodo; un nodo aislado sabe que es minoría y para sus servicios, lo que evita el *split-brain*).

**Fencing con `fence_pve`:**

```bash
# Shell de Proxmox (PROC): usuario con minimo privilegio
pveum user add fence@pve --comment "Fencing del cluster cibernova-g3"
pveum passwd fence@pve
pveum role add FenceCiberNova --privs "VM.PowerMgmt VM.Audit"
pveum acl modify /vms/128 --users fence@pve --roles FenceCiberNova && pveum acl modify /vms/129 --users fence@pve --roles FenceCiberNova && pveum acl modify /vms/130 --users fence@pve --roles FenceCiberNova
pveum user permissions fence@pve
```

```bash
# LNX01 (con un espacio delante para que no quede en el historial)
 sudo fence_pve --ip=192.168.202.3 --username=fence@pve --password='...' --pve-node=PROC --plug=129 --action=status --ssl-insecure
 sudo pcs stonith create fence-proxmox fence_pve ip=192.168.202.3 username=fence@pve password='...' pve_node=PROC vmtype=qemu ssl_insecure=1 pcmk_host_map="lnx01:128;lnx02:129;bkp01:130"
sudo pcs stonith fence lnx02     # prueba real
sudo pcs status && sudo pcs stonith history
```

- `pcmk_host_map` traduce el nombre del nodo al VMID de Proxmox (regla 100 + octeto).
- `vmtype=qemu` es obligatorio en `pcs` (sin él: `required stonith option 'vmtype' is missing`).
- **Prueba:** `pcs stonith fence lnx02` → reinicio por la API de Proxmox, quórum mantenido con LNX01 y BKP01, LNX02 de vuelta en menos de 2 minutos (`reboot of lnx02 successful: delegate=bkp01, origin=lnx01`).
- **Riesgos aceptados:** la contraseña de `fence@pve` queda en el CIB de Pacemaker (legible por `root`/`hacluster`; compensado por el mínimo privilegio) y `ssl_insecure=1` por el certificado autofirmado de Proxmox (Fase 3: instalar la CA de Proxmox y quitarlo).

**Capturas** (prefijo `2026-11-23_sesion03_`): `lnx01_hosts-antes`, `*_hosts-*`, `lnx01_hora`, `bkp01_ping-nodos`, `*_paquetes-pacemaker`, `*_cluster-debian`, `*_cluster-destroy`, `*_sin-cluster`, `lnx01_pcs-host-auth`, `lnx01_pcs-cluster-setup`, `lnx01_pcs-cluster-start`, `lnx01_pcs-status-3-nodos`, `lnx01_quorum`, `proxmox_usuario-fence`, `lnx01_fence-pve-status`, `lnx01_stonith-error-vmtype`, `lnx01_pcs-status-stonith`, `lnx01_fence-lnx02-offline`, `lnx01_fence-lnx02-vuelve-historial`.

### 2.4 Precauciones con los controladores de dominio

- **DC02 no se puede crear clonando DC01.** Un DC promovido no se clona nunca. DC02 se crea con una instalación limpia de Windows Server 2025 (o clonando una plantilla **sin dominio** a la que se haya pasado `sysprep /generalize /oobe /shutdown`), y después se promueve como DC adicional del dominio `cibernova.local`.
- Importar cada DC **una sola vez** y **dejar apagada para siempre (o borrar)** la copia de VirtualBox. Dos DC01 encendidos a la vez (misma IP y nombre) corrompen el dominio.
- No restaurar nunca un OVA o instantánea antigua de un DC después de que haya replicado con el otro (problema de *USN rollback*). Para recuperar un DC se usa la copia de *system state*.
- **Dónde se promociona DC02 (decidido por Max el 19/11, confirmado con Oriol):** en **VirtualBox**, en el mismo equipo que DC01 y con las dos VMs en adaptador puente. Se comprueba la replicación allí y después se exportan e importan en Proxmox **los dos DC**, arrancando primero DC01 y volviendo a poner las IP. Alternativas descartadas: promocionar en Proxmox (obliga a importar antes DC01, D-05, y gasta tiempo de sesión) y red interna de VirtualBox. Procedimiento completo: [guía 07](07-guia-dominio-dc02-union.md), apartado 2.
- **Resultado (19/11):** DC02 promovido y replicando (`repadmin /replsummary` 0 errores, SYSVOL en estado 4, usuario de prueba replicado). Incidencias: DNS de la tarjeta mal escrito (192.168.**102**.23) y el asistente solo aceptó la credencial en formato UPN (`Administrador@cibernova.local`, no `CIBERNOVA\Administrador`). Hora desde DC01, GPO de dominio aplicadas y los 5 roles FSMO en DC01.

### 2.5 Trabajo en casa con las VMs Ubuntu (propuesta pendiente de decidir)

> **Actualización 17/11:** para construir LNX01 desde cero, Max eligió VirtualBox → OVA (apartado 2.3). La propuesta de abajo sigue pendiente para los servicios que se monten **después** de importar (SQL Server, Pacemaker, Apache…), cuando las VMs ya estén en Proxmox.

LNX02, BKP01 y BKP02 ya están en Proxmox. Para trabajar en casa con el servidor apagado se plantea crear copias en VirtualBox. **Propuesta:** en lugar de volver a importar máquinas enteras, **pasar la configuración, no la máquina**:

1. En VirtualBox, una VM Ubuntu 24.04 de pruebas por servicio.
2. Cada configuración se guarda en el repositorio (`configs/linux/`) y cada instalación en un script (`scripts/linux/`).
3. En la sesión, en la VM de Proxmox: `git pull` y ejecutar el script o copiar los ficheros.

**Ventajas:** no se pisan IPs, nombres ni claves de las VMs de Proxmox; todo queda versionado en Git (cuenta para la nota) y se puede repetir si hay que reinstalar. **[PENDIENTE DE DECIDIR]** por Max.

---

## 3. DC01 – Controlador de dominio principal

### 3.1 Pasos realizados (en VirtualBox)

1. Instalación de Windows Server 2025.
2. **IP fija** 192.168.202.23, máscara 255.255.252.0, puerta de enlace 192.168.200.254 y DNS 127.0.0.1 (confirmado con `ipconfig /all`, 16/11).
3. Comprobación de **ping** con la máquina anfitriona.
4. **Cambio de nombre** del equipo a DC01 y reinicio.
5. Instalación del rol **Servicios de dominio de Active Directory**.
6. **Promoción** a controlador de dominio: **nuevo bosque** `cibernova.local`. Reinicio automático.
7. Comprobación de que el dominio está instalado correctamente.

### 3.2 Configuración DNS recomendada tras importar en Proxmox

- DNS de la tarjeta de DC01: **preferido 192.168.202.24 (DC02)**, alternativo **127.0.0.1** (práctica recomendada por Microsoft cuando hay dos DC). Mientras DC02 no exista: preferido 127.0.0.1.
- **Reenviadores** del servidor DNS: 8.8.8.8 y 1.1.1.1 (el DNS del aula, 192.168.200.254, no responde; ver 3.3).
- Comprobar con `dcdiag /test:dns` y `nslookup cibernova.local`.
- **Estado (16/11, DC01 en VirtualBox en un equipo del aula):** reenviador configurado; `dcdiag /test:dns` supera todas las pruebas salvo *Reenviadores*: la VM de VirtualBox no tiene salida a Internet (solo red del aula), así que el reenviador no puede resolver nombres externos. **Corregido el 18/11:** DC01 sí tiene Internet; lo que falla es el DNS del aula, que además intercepta todo el tráfico DNS (apartado 3.3).

### 3.3 Configuración del servicio DNS (script 04, 17/11/2026)

**Requisito:** el enunciado (Fase 1) pide desplegar **DNS** como servicio, **redundante** y **documentado**. DC01 ya resolvía el dominio (zona `cibernova.local` creada al promocionar y reenviador al aula), pero faltaba completar y endurecer el servicio. Se preparó `scripts/windows/04-configurar-dns.ps1` (idempotente) con su comprobación `93-comprobar-dns.ps1`; finalmente la configuración se hizo por la interfaz gráfica (ver Estado).

**Diagnóstico de la red del aula (18/11):** con 127.0.0.1 como único DNS y solo los servidores raíz, DC01 daba SERVFAIL. Un servidor raíz (198.41.0.4) devolvió las IP de `www.google.com`, cosa que un servidor raíz real nunca hace, con un TTL de caché (33620 en lugar de 518400), y no contestaba a las consultas sin recursión. **Conclusión: la red del aula intercepta todo el tráfico DNS** y no permite que un servidor resuelva por sí mismo desde la raíz. Desactivar EDNS no cambió nada.

| # | Configuración | Por qué | Alternativa descartada |
|---|---|---|---|
| 1 | Zona directa `cibernova.local` **integrada en AD** | Se replica sola a DC02 con la replicación de AD: DNS redundante sin configurar zonas secundarias. | Zona primaria en fichero + secundaria en DC02: dos configuraciones y un único servidor que acepta cambios. |
| 2 | **Solo actualizaciones dinámicas seguras** | Solo los equipos del dominio (autenticados con Kerberos) pueden registrar o cambiar sus nombres. Evita que un equipo cualquiera de la red compartida del aula suplante un nombre. | Seguras y no seguras: cualquiera podría registrar `fs01`. |
| 3 | **Transferencias de zona desactivadas** | Con zonas integradas en AD no hacen falta; dejarlas abiertas permite descargar todo el inventario de nombres (hallazgo típico de auditoría, Fase 3). | Permitir a los servidores de nombres: innecesario. |
| 4 | **Zona inversa** `202.168.192.in-addr.arpa` (192.168.202.0/24), integrada en AD | Resolución IP → nombre: la usan `nslookup`, los registros de auditoría y algunos servicios (Kerberos, SQL Server, SSH). Todas las VMs y el host están en 192.168.202.x, así que basta una zona /24 aunque la red sea /22. | Cuatro zonas /24 para todo el /22: el resto del /22 es de otros grupos. |
| 5 | **Reenviadores 8.8.8.8 (Google) y 1.1.1.1 (Cloudflare)** + sugerencias de raíz como respaldo (cambio del 18/11/2026; corregido a las 17:35: se había anotado 1.1.1.1 y 9.9.9.9) | La red del aula **intercepta el DNS**: el .254 no responde y la resolución propia desde los servidores raíz da SERVFAIL (diagnóstico en la bitácora, 18/11). Dos reenviadores de **proveedores distintos** para tener redundancia. La tarjeta de DC01 sigue solo con 127.0.0.1, así que DC01 es el DNS de todo el dominio y solo reenvía lo de Internet. | (a) DNS del aula .254: no responde. (b) Solo servidores raíz (resolución propia, la opción preferida): imposible con la intercepción; se recuperará si el profesorado da DNS sin interceptar. (c) 8.8.8.8 en la tarjeta: mala práctica en un DC (las consultas de `cibernova.local` podrían salir fuera). (d) 1.1.1.1 y 9.9.9.9 para no depender de Google: valorada, no aplicada. |
| 6 | **Registros fijos A + PTR** de `lnx01`, `lnx02`, `bkp01`, `bkp02` | Los Ubuntu no se registran solos en el DNS de Windows (SSSD puede, pero se prefiere un registro fijo para servidores). | `dyndns_update` de SSSD: depende de que la unión funcione y es más difícil de explicar. |
| 7 | `www`, `sftp`, `sqlag` → VIP 192.168.202.27 (creados el 18/11) | Los clientes usan un nombre de servicio que sigue a la VIP de Pacemaker, sin depender de qué nodo está activo. | Apuntar a `lnx01`: dejaría de funcionar al conmutar. |
| 8 | **Envejecimiento y limpieza** (7 + 7 días) | Borra registros dinámicos de equipos que ya no existen (p. ej. una VM rehecha con otro nombre). Los registros fijos no caducan. Al cargar la zona, Windows espera un intervalo antes de limpiar, así que apagar el laboratorio en vacaciones no borra nada. | Sin limpieza: registros obsoletos con el tiempo. |
| 9 | DNS de la tarjeta de DC01: **.24 + 127.0.0.1** (desde el 19/11; antes solo 127.0.0.1) | Recomendación de Microsoft para dos DC (ver 3.2). | — |

**Redundancia:** las zonas (directa e inversa) se replican a DC02 al promocionarlo con `-InstallDns`. Los **reenviadores no se replican**: hay que configurarlos también en DC02. **DC02 (19/11):** reenviadores **8.8.8.8 y 1.1.1.1**. Al promocionar, el asistente puso DC01 como reenviador de DC02, y en DC01 se había puesto DC02: **se quitan los dos**, porque *evita bucles y dependencia mutua* (cada DC ya tiene las zonas replicadas y, si uno cae, el otro sigue resolviendo Internet). Comprobado en DC02 con `nslookup` directo e inverso de lnx01 contra 127.0.0.1. Las tarjetas quedan con DNS cruzado: DC01 → .24 + 127.0.0.1; DC02 → .23 + 127.0.0.1.

Comprobación en DC02: `93-comprobar-dns.ps1 -Servidor 192.168.202.24`.

**Ejecución en DC01:**
```powershell
cd C:\CiberNova
powershell -ExecutionPolicy Bypass -File .\04-configurar-dns.ps1
```
**Estado:** el script 04 v1.0 se ejecutó en DC01 el 17/11 y después se deshizo con `84-deshacer-dns.ps1` v1.0 para empezar de cero. El 18/11 se configuró todo lo de la tabla **por la interfaz gráfica** (Administrador de DNS) y se verificó con `nslookup` y `dcdiag /test:dns`; los reenviadores quedaron en 8.8.8.8 y 1.1.1.1. El script 04 v1.2 hace lo mismo y queda como forma reproducible de configurarlo (por ejemplo, en DC02 o si hay que reinstalar). DC01 resuelve `cibernova.local` e Internet con 127.0.0.1 como único DNS de la tarjeta.

### 3.4 GPO de seguridad (script 05, 18/11/2026)

Los scripts 01–03 no crean GPO (se aplazaron el 16/11). Se crean con `scripts/windows/05-gpo.ps1` v1.1 y se comprueban con `94-comprobar-gpo.ps1` v1.0, que además guarda un informe HTML de cada GPO en `C:\CiberNova\informes-gpo\`.

| GPO | Vinculada en | Configuración | Por qué |
|---|---|---|---|
| `GPO_Dominio_CuentasServicio` | Dominio | Denegar inicio de sesión local y por Escritorio remoto a `G_Cuentas_Servicio` | Anexo I, ap. 5: las cuentas `svc_*` no inician sesión interactiva. Los servicios que las usan siguen funcionando (inicio de sesión de servicio). En los Linux unidos, SSSD aplica también la denegación (SSH) |
| `GPO_Equipos_SinCuentasAdm` | OU Equipos | Lo mismo para `G_Admin_Sistemas` (solo las 6 cuentas `adm.`) | Anexo I, ap. 5: las cuentas `adm.` no se usan en los equipos de usuarios. En los servidores sí pueden entrar |
| `GPO_Dominio_Firewall` | Dominio | Firewall activado en los 3 perfiles, entrada bloqueada, salida permitida, reglas locales respetadas y regla de ping | Compensa la red plana sin VLAN (diseño 3.11). Las reglas que crean los roles (AD, DNS, DFS) se mantienen |
| `GPO_Servidores_Auditoria` | OU Servidores | Auditoría avanzada: sistema de archivos e inicio de sesión (correcto y error) + forzar subcategorías | Base de P-11, P-39 y la prueba 15; las carpetas se marcarán (SACL) con FS01/FS02 |

**Alternativa descartada:** crearlas a mano en `gpmc.msc` (se dieron los pasos gráficos), porque con script quedan versionadas y se pueden repetir.

**Incidencia:** la v1.0 se paró en el firewall: `Get-NetFirewallRule` no admite `-GPOSession`. La v1.1 busca la regla con `-PolicyStore` y, al ser idempotente, la segunda ejecución completó lo que faltaba.

**Estado (18/11):** ejecutado en DC01; `gpupdate /force` y `94-comprobar-gpo.ps1` → **25 OK, 0 FALLO**. DC01 aplica las GPO de cuentas de servicio y de firewall. Las de Equipos y Servidores se comprobarán al unir CLI01/CLI02 y FS01/FS02. Lo que no hace, a propósito: el privilegio de copia de `svc_backup` (con FS01/FS02 y Bareos).

### 3.5 Incidencias

- La instalación del rol de dominio tardó mucho, pero funcionó a la primera.

---

## 4. Estructura de Active Directory (creada)

Script: [`scripts/windows/01-crear-ou-grupos.ps1`](../../scripts/windows/01-crear-ou-grupos.ps1)

```
cibernova.local
└── CiberNova
    ├── Usuarios
    │   ├── Direccion
    │   ├── Administracion
    │   ├── RRHH
    │   ├── Comercial
    │   ├── Marketing
    │   ├── Consultoria
    │   ├── Desarrollo
    │   ├── Sistemas
    │   ├── Soporte
    │   └── Legal
    ├── Grupos
    ├── Cuentas especiales
    │   ├── Administracion   (cuentas adm.*)
    │   └── Servicios        (svc_*)
    ├── Equipos
    │   ├── Barcelona
    │   ├── Madrid
    │   ├── Valencia
    │   └── Recepcion        (BCN-RECEPCION)
    ├── Servidores
    └── Bajas
```

- Todas las OU están protegidas contra el borrado accidental.
- **OU Equipos y Servidores (script 01 v2.1, 16/11/2026):** el contenedor por defecto `Computers` no admite GPO, así que los equipos de cada sede, el de recepción (BCN-RECEPCION) y los servidores miembros (FS01, FS02) irán a estas OU. Los controladores de dominio no se mueven de `Domain Controllers`. Con la v2.1 el total de OU bajo CiberNova pasa de 17 a **23**. Ejecutado en DC01 el 16/11 (`90-comprobar-ou-grupos.ps1`: 23 OU y 27 grupos).
- **Opcional, a decidir más adelante:** `redircmp "OU=Equipos,OU=CiberNova,DC=cibernova,DC=local"` hace que los equipos nuevos entren directamente en la OU Equipos en lugar de en `Computers`.

Los grupos, cuentas y políticas están en el [inventario de servicios, usuarios y grupos](05-inventario-servicios-usuarios-grupos.md).

---

## 5. Alta de usuarios

Script: [`scripts/windows/02-alta-usuarios.ps1`](../../scripts/windows/02-alta-usuarios.ps1) (versión 2.2)

### 5.1 Qué hace

- Comprueba antes de empezar que existen todas las OU y grupos del script 01; si falta algo, lo lista y se detiene.
- Lee `C:\CiberNova\usuarios_cibernova.csv` (UTF-8, separador `;`) y valida que hay 89 empleados, las columnas obligatorias y que no hay usuarios duplicados.
- **Idempotente:** si la cuenta ya existe no la vuelve a crear ni le cambia la contraseña; solo completa o corrige sus grupos y restricciones.
- Cada usuario va a la OU de su departamento, con departamento, puesto y **oficina (sede)**.
- Contraseña inicial aleatoria de 20 caracteres (24 para las adm.), que no contiene el usuario ni partes del nombre, y **cambio obligatorio en el primer inicio de sesión**.
- Contraseñas iniciales **cifradas con DPAPI** en `C:\CiberNova-Privado` (sin herencia; solo el usuario que ejecuta el script, SYSTEM y Administradores). **Nunca se muestran ni se suben al repositorio.**
- **Becarios:** no entran en el grupo de su departamento (y se les quita si estuvieran); entran en `G_Becarios` y `G_Becarios_<Departamento>`, con horario L-V 8:00-15:00 y caducidad el 30/06/2027.
- Políticas de contraseña: general (12 caracteres) y PSO de 15 caracteres para `G_Politica_15`.
- Crea las **6 cuentas `adm.`** en `Cuentas especiales\Administracion` y añade `G_Admin_Sistemas` a **Admins. del dominio** (buscado por SID, porque el nombre cambia según el idioma de Windows).
- Guarda un registro de cada ejecución en `C:\CiberNova-Privado\logs`.

### 5.2 Error de la versión 1 y corrección

La versión 1 dio error al ejecutarse. Revisando el código se encontraron estos fallos:

| # | Fallo en la v1 | Efecto | Corrección en la v2 |
|---|---|---|---|
| 1 | `Set-ADUser -LogonHours`: ese parámetro **no existe** | Error *"A parameter cannot be found that matches parameter name 'LogonHours'"* en el primer becario (nerea.ruiz); el script se detenía ahí | `Set-ADUser -Replace @{ logonHours = [byte[]]... }` |
| 2 | Orden de bits del horario invertido | Los becarios habrían podido entrar a horas equivocadas | El bit menos significativo de cada byte es la primera hora |
| 3 | La OU se creaba como "Cuentas especiales" y se buscaba como "Cuentasespeciales" (sin espacio) | No se creaban las sub-OU ni las cuentas adm. | El nombre se define una sola vez |
| 4 | El resumen del script 01 usaba `Get-ADOrganizationalUnit` sin `-Filter` | Windows pedía el filtro por pantalla | `-Filter *` |
| 5 | Caracteres no ASCII en el código (tildes y un guion largo "—") con el fichero guardado sin BOM | Windows PowerShell 5.1 lo lee como Windows-1252: el guion largo se convierte en `â€”` y su `”` cuenta como comillas de cierre. Error real en DC01: *Token 'G_")) {...' inesperado* y *Falta la cadena en el terminador*. Las tildes salían como "AdministraciÃ³n" | **v2.1:** script 100 % ASCII; guion largo y tildes con `[char]0x....` (detalle en la bitácora, 16/11 noche) |
| 6 | Contraseñas aleatorias que podían contener partes del nombre | Error de complejidad de Windows (poco probable, pero posible) | Se generan otra vez si contienen el usuario o el nombre |
| 7 | Las cuentas adm. no tenían privilegios de administración | No cumplía el Anexo I, apartado 5 | `G_Admin_Sistemas` en Admins. del dominio |
| 8 | (v2.1) La comprobación previa exigía `G_Politica_15` y `G_Admin_Sistemas`, que en la v2 crea el script 01; en DC01 se ejecutó el 01 antiguo | Se detenía con *"FALTA -> Grupo: G_Politica_15 / G_Admin_Sistemas"* | **v2.2:** el script 02 crea esos dos grupos si faltan |

**Pruebas realizadas** (simulando Active Directory con PowerShell 7, fuera de Windows; la v2.1 también se analizó leyéndola como Windows-1252, igual que Windows PowerShell 5.1): dos ejecuciones seguidas de cada script sin errores; la segunda no crea nada nuevo. Resultado: 89 empleados + 6 adm., miembros de cada grupo iguales a los del inventario, horario de `izan.moreno` exactamente L-V 8:00-15:00, `G_Admin_Sistemas` dentro de Admins. del dominio, y error controlado con lista de lo que falta si se ejecuta el 02 sin el 01. **Pendiente: repetir la prueba en DC01 real.**

### 5.3 Cómo volver a ejecutarlo en DC01

1. Copiar los dos scripts a `C:\CiberNova\` y el CSV a `C:\CiberNova\usuarios_cibernova.csv`.
2. Abrir **PowerShell como administrador**:

```powershell
cd C:\CiberNova
powershell -ExecutionPolicy Bypass -File .\01-crear-ou-grupos.ps1
powershell -ExecutionPolicy Bypass -File .\02-alta-usuarios.ps1
```

3. Comprobaciones (con captura). Los scripts `90-comprobar-ou-grupos.ps1` y `91-comprobar-usuarios.ps1` muestran todo esto de forma ordenada para la captura:
   - El resumen final: 89 empleados, 6 cuentas adm. y miembros por grupo (comparar con el [inventario](05-inventario-servicios-usuarios-grupos.md)).
   - *Usuarios y equipos de AD → izan.moreno → Propiedades → Cuenta → Horas de inicio de sesión*: L-V de 8:00 a 15:00.
   - `Get-ADGroupMember "G_Admin_Sistemas"` y que G_Admin_Sistemas aparece en Admins. del dominio.
   - Si en el dominio existe una OU vacía llamada `Cuentasespeciales` (sin espacio) de la ejecución anterior, quitarle la protección y borrarla.

> Como la v1 se detuvo a mitad, puede que parte de los usuarios ya existan. No pasa nada: la v2 los detecta, no los duplica y completa lo que les falte. Sus contraseñas iniciales ya se guardaron en la ejecución anterior.

### 5.4 Cuentas especiales (script 03)

Script: [`scripts/windows/03-cuentas-especiales.ps1`](../../scripts/windows/03-cuentas-especiales.ps1) (versión 1.0). Configuración de cada cuenta y decisiones en el [inventario, apartado 6.1](05-inventario-servicios-usuarios-grupos.md#61-configuración-de-cada-cuenta-especial-script-03).

```powershell
cd C:\CiberNova
powershell -ExecutionPolicy Bypass -File .\03-cuentas-especiales.ps1

# Cuando se sepa el fin de la Fase 3 (ejemplo de fecha):
powershell -ExecutionPolicy Bypass -File .\03-cuentas-especiales.ps1 -CaducidadAuditor "2027-06-15"
```

- Idempotente: si una cuenta ya existe no cambia su contraseña; solo corrige restricciones y grupos.
- `auditor.ext` se crea deshabilitada y el script **nunca la vuelve a deshabilitar**, para que se pueda habilitar cuando lo indique el profesorado sin que una nueva ejecución la desactive.
- Probado con Active Directory simulado: dos ejecuciones sin errores; horario de auditor.ext exactamente L-V 8:00-20:00; tras habilitar auditor.ext a mano, la segunda ejecución la deja habilitada y añade la caducidad.

**Comprobación (con captura):** `powershell -ExecutionPolicy Bypass -File .\92-comprobar-cuentas-especiales.ps1` (26 comprobaciones con OK / FALLO). También se puede usar este comando:

```powershell
Get-ADUser -Filter * -SearchBase "OU=Cuentas especiales,OU=CiberNova,DC=cibernova,DC=local" -SearchScope Subtree `
  -Properties CannotChangePassword,PasswordNeverExpires,LogonWorkstations,AccountExpirationDate |
  Where-Object SamAccountName -notlike "adm.*" |
  Format-Table SamAccountName,Enabled,CannotChangePassword,PasswordNeverExpires,LogonWorkstations,AccountExpirationDate
```

**Procedimiento de rotación de contraseñas de las cuentas de servicio y de recepcion.bcn** (el Anexo I pide un procedimiento documentado si no se usa gMSA):

1. Frecuencia: una vez al año, al cambiar de responsable en Sistemas o ante cualquier sospecha de filtración.
2. Generar una contraseña nueva de 32 caracteres (16 para recepcion.bcn) con un gestor de contraseñas.
3. Cambiarla en AD con una cuenta `adm.`: `Set-ADAccountPassword -Identity svc_web -Reset -NewPassword (Read-Host -AsSecureString)`.
4. Actualizarla en el servicio que la use (Bareos, Apache, SQL Server…) y comprobar que el servicio arranca.
5. Guardarla en el gestor de contraseñas del equipo; nunca en documentos, Drive ni Git.
6. Apuntar la fecha del cambio en la bitácora.

---

## 6. Credenciales

Las contraseñas no se escriben en la documentación, Drive ni Git (requisito del Anexo I y de la auditoría de la Fase 3).

**Riesgo aceptado (17/11/2026):** durante el montaje (Fases 1 y 2) se usan contraseñas sencillas para poder recordarlas. Al empezar la Fase 3 se cambian todas y se guardan en un gestor de contraseñas (KeePassXC o Proton Pass, **[PENDIENTE DE CONFIRMAR]**). La red del aula es compartida con otros grupos, así que no se reutiliza la misma contraseña en todas las máquinas. Propuesta: mantener desde ya un inventario de **dónde** se usa cada credencial (nunca la contraseña): `admincibernova` en cada Ubuntu, `hacluster` (Pacemaker), usuario de `fence_pve` en Proxmox, `sa` y login del AG en SQL Server, `svc_backup` (Bareos).

---

## 7. Pendiente

> La lista completa y ordenada está en [`docs/gestion/lista-tareas-fase1.md`](../gestion/lista-tareas-fase1.md). Aquí solo se resume lo inmediato de las VMs ya construidas.

- [x] Ejecutar el script 02 v2.2 en DC01 y hacer las capturas (16/11).
- [ ] Exportar DC01 a OVA, importarlo en Proxmox y comprobar red, DNS (`dcdiag /test:dns`) y rendimiento (pasa a la sesión 2, D-05).
- [x] Crear DC02 (instalación limpia, no clon de DC01), promoverlo y comprobar la replicación (`repadmin /replsummary`): 19/11, en VirtualBox.
- [ ] Exportar DC01 y DC02 a OVA e importarlos en Proxmox (123 y 124, DC01 primero).
- [x] LNX01 instalada en VirtualBox y exportada a OVA (17/11, apartado 2.3.1).
- [x] Importar LNX01 en Proxmox (VMID 128, 17/11). WEB01 y las demás VMs antiguas, borradas.
- [x] Netplan fijo de LNX01 con DNS públicos (17/11).
- [x] SQL Server 2025 instalado en LNX01 (sin configurar). LNX02 clonada y personalizada (17/11).
- [x] Personalizar BKP01 (.30, 18/11) y crear BKP02 (131, .31, 19/11, desde `base-limpia`).
- [x] `mssql-conf setup` en LNX01, LNX02 (Enterprise Developer) y BKP01 (Express); `hadr.hadrenabled` activado en las tres y Agente en LNX01/LNX02 (19/11).
- [x] Pacemaker + Corosync (`cibernova-g3`) de 3 nodos y fencing con `fence_pve`, probado (23/11, apartado 2.3.7).
- [ ] AG de SQL Server (certificados, *endpoints*, réplica de solo configuración en BKP01), recursos de Pacemaker y VIP .27.
- [ ] **Todo subido a GitHub antes del 4/12/2026** (cierre del repositorio).
- [x] OU Equipos y Servidores: script 01 v2.1 ejecutado en DC01, 23 OU (16/11).
- [x] Ejecutar `03-cuentas-especiales.ps1` en DC01: 26 comprobaciones OK (16/11).
- [ ] Caducidad de `auditor.ext` cuando se sepa el fin de la Fase 3.
- [ ] GPO pendientes: privilegio de copia para `svc_backup`; perfiles (móvil, redirección, obligatorio de `recepcion.bcn`) y unidades de red.
- [ ] Carpetas personales (creadas por el script de alta), cuotas y perfiles (cuando esté el servidor de ficheros).
- [x] Configurar el DNS de DC01 (script 04, 17/11; deshecho con el 84 y rehecho por la interfaz gráfica el 18/11; reenviadores 8.8.8.8 y 1.1.1.1).
- [x] GPO de seguridad (script 05 v1.1, 18/11): 25 OK.
- [ ] Unir todas las máquinas al dominio ([guía 07](07-guia-dominio-dc02-union.md)).
