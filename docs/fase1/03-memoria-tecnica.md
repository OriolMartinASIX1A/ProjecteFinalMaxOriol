# Memoria técnica de la infraestructura desplegada – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Versión:** 0.15 · 27/11/2026 (Oriol, 26–27/11: prioridad de referencias DFS e informe de DFS-R, apartado 2.7; permisos P-01 a P-44, carpetas personales, cuotas, perfiles, GPO de unidades y redirección, hora del dominio y OVA de los Windows, apartado 2.8) · v0.14 · 27/11/2026 (sesión 4 Linux: base de datos en el AG, conmutaciones y tiempos medidos, Apache + PHP-FPM en Pacemaker, usuario `web_cibernova`, firewall `ufw`, apartado 2.3.9) · v0.13 · 24/11/2026 (FS02 y replicación DFS-R, apartado 2.7) · v0.12 · 24/11/2026 (AG de SQL Server en Pacemaker con VIP .27, apartado 2.3.8; FS01: carpetas del espacio de nombres y replicación con DC02, apartado 2.6) · v0.11 · 23/11/2026 (FS01 en VirtualBox: dominio, disco de datos, roles, espacio de nombres y recursos compartidos, apartado 2.6) · v0.10 · 23/11/2026 (clúster Pacemaker de 3 nodos y fencing, apartado 2.3.7) · v0.9 · 19/11/2026 (sesión 2 Linux: SQL Server configurado, BKP01 y BKP02, apartado 2.3.6) · v0.8 · 19/11/2026 (DC02 promovido; reenviadores de DC02, apartado 3.3) · v0.7 · 19/11/2026 (DC02 en VirtualBox, apartado 2.4) · v0.6 · 19/11/2026 (reenviadores corregidos a 8.8.8.8 y 1.1.1.1; scripts 04 y 93 v1.2) · v0.5 · 18/11/2026 (sesión 1 y DNS/GPO de DC01)

> Documento vivo: se amplía al terminar cada servicio. Lo marcado con **[PENDIENTE DE CONFIRMAR]** hay que verificarlo.

---

## 1. Estado actual (27/11/2026)

| VM | Estado | Dónde está | Notas |
|---|---|---|---|
| Host Proxmox | Instalado (Proxmox VE 9.2.21, nodo `PROC`) | Servidor físico (192.168.202.3) | Ver [guía del hipervisor](02-guia-instalacion-hipervisor.md) |
| DC01 | **AD completo** (16/11): bosque `cibernova.local`, 23 OU, 27 grupos, 89 empleados, 6 cuentas adm., 6 cuentas especiales y políticas de contraseña. **DNS configurado y verificado** (18/11, apartado 3.3) y **GPO de seguridad** (18/11, apartado 3.4). Hora con `hora.roa.es` (raíz de la jerarquía de hora del dominio, 26/11). 63 grupos `DL_`, GPO de unidades y de redirección (26/11). **No se importó el 17/11 (D-05).** | **OVA exportada el 27/11**, pendiente de importar en Proxmox (VMID 123) | Apartado 2.8 |
| DC02 | **Promovido el 19/11 en VirtualBox** (DNS + catálogo global), replicando con DC01 | **OVA exportada el 27/11**, pendiente de importar en Proxmox (VMID 124) después de DC01 | Ver precauciones del apartado 2.4 y [guía 07](07-guia-dominio-dc02-union.md), apartado 2 |
| LNX01 | **Proxmox (VMID 128)**: Ubuntu 24.04.5, IP .28 fija, DNS públicos, **SQL Server 2025 Enterprise Developer** con Always On y Agente. Réplica del AG `sqlag_cibernova` (24/11) con `cibernova_pruebas`; Apache + PHP-FPM con `sqlsrv` (26/11); `ufw` activo (26/11) | **Proxmox** | Importación manual (el asistente falló). Apartados 2.3, 2.3.6, 2.3.8 y 2.3.9 |
| LNX02 | **Proxmox (VMID 129)**: clon de LNX01 personalizado, IP .29, **SQL Server 2025 Enterprise Developer** con Always On y Agente. Réplica del AG (24/11); **réplica principal, VIP .27 y Apache al terminar el 26/11**; Apache + PHP-FPM con `sqlsrv`. `ufw` pendiente | Proxmox | Apartados 2.3.4, 2.3.6, 2.3.8 y 2.3.9 |
| BKP01 | **Proxmox (VMID 130)**: clon personalizado (18/11), IP .30, **SQL Server 2025 Express**, **réplica de solo configuración del AG** (24/11) y tercer nodo Pacemaker; `ufw` activo (26/11) | Proxmox | Apartados 2.3.4, 2.3.6, 2.3.8 y 2.3.9 |
| BKP02 | **Proxmox (VMID 131)**: clon de la instantánea `base-limpia` (sin SQL Server), personalizado, IP .31 | Proxmox | Apartado 2.3.6. Bareos pendiente |
| FS01 | **Configuración base (23/11):** unida al dominio (OU Servidores), D: `Datos` de 150 GB, roles de ficheros, espacio de nombres `\\cibernova.local\empresa` con ABE y cuatro recursos compartidos ocultos. **26/11:** prioridad en las referencias, 50 carpetas con los permisos de la matriz, 89 carpetas personales, cuotas y `Perfiles$` | **OVA exportada el 27/11**, pendiente de importar en Proxmox (VMID 125) | Apartados 2.6 y 2.8 |
| FS02 | **Configurada (24/11):** unida al dominio (OU Servidores), D: de 150 GB, roles, cuatro recursos compartidos, segundo servidor del espacio de nombres y **DFS-R con FS01** probada; permisos replicados (script 96: 0 errores), cuotas y `Perfiles$` (26/11) | **OVA exportada el 27/11**, pendiente de importar en Proxmox (VMID 126) | Apartados 2.7 y 2.8 |
| Clientes | Sin crear | — | — |

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

### 2.3.8 Grupo de disponibilidad de SQL Server en Pacemaker (24/11, sesión 3)

**Punto de partida:** el clúster `cibernova-g3` vuelve a formarse solo tras el apagado del 23/11 y `mssql-server` está activo en los tres nodos. `ufw` inactivo; SQL Server escucha en el 1433.

**1. Certificado para que las réplicas se autentiquen** (sin depender del dominio). Las órdenes con contraseña se escriben en `sqlcmd` interactivo (no quedan en el historial de bash):

```sql
-- LNX01 (sqlcmd -S localhost -U sa -C)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '...';
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'CiberNova AG', EXPIRY_DATE = '20281231';
BACKUP CERTIFICATE dbm_certificate TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/dbm_certificate.pvk', ENCRYPTION BY PASSWORD = '...');
```

- `EXPIRY_DATE = '2028-12-31'` falla con *Msg 190*: SQL Server en castellano lee día-mes-año. El formato `AAAAMMDD` vale en cualquier idioma. Sin fecha, el certificado caduca al año, antes de la Fase 3.

```bash
# LNX01: copiar a los otros nodos (el * lo expande root, porque el usuario no puede leer la carpeta)
sudo sh -c 'cp /var/opt/mssql/data/dbm_certificate.* /tmp/ && chown admincibernova /tmp/dbm_certificate.*'
scp /tmp/dbm_certificate.* admincibernova@lnx02:/tmp/ && scp /tmp/dbm_certificate.* admincibernova@bkp01:/tmp/
rm /tmp/dbm_certificate.*
# LNX02 y BKP01
sudo sh -c 'mv /tmp/dbm_certificate.* /var/opt/mssql/data/ && chown mssql:mssql /var/opt/mssql/data/dbm_certificate.* && chmod 660 /var/opt/mssql/data/dbm_certificate.*'
sudo ls -l /var/opt/mssql/data/ | grep dbm
```

```sql
-- LNX02 y BKP01
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '...';
CREATE CERTIFICATE dbm_certificate FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/dbm_certificate.pvk', DECRYPTION BY PASSWORD = '...');
SELECT name, expiry_date FROM sys.certificates WHERE name = 'dbm_certificate';   -- 2028-12-31 en los tres
```

**2. *Endpoints* (puerto 5022, autenticación por certificado y cifrado AES):**

```sql
CREATE ENDPOINT [Hadr_endpoint] AS TCP (LISTENER_PORT = 5022)
FOR DATABASE_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE dbm_certificate, ENCRYPTION = REQUIRED ALGORITHM AES);
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
-- En BKP01, ROLE = WITNESS: con SQL Server Express es el único valor válido
SELECT name, state_desc, role_desc FROM sys.database_mirroring_endpoints;
```

**3. AG `sqlag_cibernova`** (nombre decidido por Max: distinto del listener `sqlag`):

| Réplica | Modo | Conmutación | Papel |
|---|---|---|---|
| `lnx01` | `SYNCHRONOUS_COMMIT` | `EXTERNAL` (Pacemaker) | Principal al empezar |
| `lnx02` | `SYNCHRONOUS_COMMIT` | `EXTERNAL` (Pacemaker) | Secundaria; RPO = 0 |
| `bkp01` | `CONFIGURATION_ONLY` | — | Guarda la configuración y vota; sin datos |

```sql
-- LNX01
CREATE AVAILABILITY GROUP [sqlag_cibernova] WITH (CLUSTER_TYPE = EXTERNAL) FOR REPLICA ON
 N'lnx01' WITH (ENDPOINT_URL = N'tcp://lnx01:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = EXTERNAL, SEEDING_MODE = AUTOMATIC),
 N'lnx02' WITH (ENDPOINT_URL = N'tcp://lnx02:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = EXTERNAL, SEEDING_MODE = AUTOMATIC),
 N'bkp01' WITH (ENDPOINT_URL = N'tcp://bkp01:5022', AVAILABILITY_MODE = CONFIGURATION_ONLY);
ALTER AVAILABILITY GROUP [sqlag_cibernova] GRANT CREATE ANY DATABASE;
-- LNX02: JOIN + GRANT CREATE ANY DATABASE · BKP01: solo JOIN
ALTER AVAILABILITY GROUP [sqlag_cibernova] JOIN WITH (CLUSTER_TYPE = EXTERNAL);
-- Comprobación en LNX01
SELECT r.replica_server_name, r.availability_mode_desc, s.role_desc, s.connected_state_desc
FROM sys.availability_replicas r JOIN sys.dm_hadr_availability_replica_states s ON r.replica_id = s.replica_id;
```

Resultado: `lnx01 PRIMARY`, `lnx02 SECONDARY`, `bkp01 SECONDARY (CONFIGURATION_ONLY)`, las tres `CONNECTED`.

**4. Login de Pacemaker con mínimo privilegio** (en los tres):

```sql
CREATE LOGIN pacemakerLogin WITH PASSWORD = '...';
GRANT ALTER, CONTROL, VIEW DEFINITION ON AVAILABILITY GROUP::sqlag_cibernova TO pacemakerLogin;
GRANT VIEW SERVER STATE TO pacemakerLogin;
```

```bash
 printf 'pacemakerLogin\n...\n' | sudo tee /var/opt/mssql/secrets/passwd > /dev/null    # con un espacio delante
sudo chown root:root /var/opt/mssql/secrets/passwd && sudo chmod 400 /var/opt/mssql/secrets/passwd
# Comprobación sin mostrar la contraseña (ruta completa: root no tiene sqlcmd en el PATH)
sudo sh -c '/opt/mssql-tools18/bin/sqlcmd -S localhost -C -U "$(sed -n 1p /var/opt/mssql/secrets/passwd)" -P "$(sed -n 2p /var/opt/mssql/secrets/passwd)" -Q "SELECT SUSER_NAME()"'
```

**Riesgo aceptado:** la contraseña de `pacemakerLogin` está en texto plano en ese fichero (lo exige el agente de Microsoft); lo compensan los permisos `400 root` y que el login solo tiene permisos sobre el AG.

**5. Recursos de Pacemaker** (solo desde LNX01):

```bash
ls /usr/lib/ocf/resource.d/mssql/        # ag, agv2, fci (paquete mssql-server-ha)
sudo pcs resource create ag_cluster ocf:mssql:ag ag_name=sqlag_cibernova meta failure-timeout=60s promotable notify=true
ping -c 2 192.168.202.27                 # antes de crear la VIP: tiene que fallar (IP libre)
sudo pcs resource create virtualip ocf:heartbeat:IPaddr2 ip=192.168.202.27 cidr_netmask=22 op monitor interval=10s
sudo pcs constraint colocation add virtualip with Promoted ag_cluster-clone INFINITY
sudo pcs constraint order promote ag_cluster-clone then start virtualip
sudo pcs status && ip -br addr show ens18
```

- `promotable`: el recurso corre en los tres nodos y solo uno es `Promoted` (la principal). `notify=true` lo necesita el agente de Microsoft. `failure-timeout=60s` evita que un fallo puntual bloquee un nodo para siempre.
- `pcs` avisa (*Deprecation Warning*) de que en versiones futuras `meta` irá después de `promotable`; el recurso se crea bien.
- Colocación `INFINITY` con la réplica `Promoted`: la VIP nunca está en una secundaria ni en BKP01. Orden `Mandatory`: la VIP solo se levanta cuando ya hay principal.

Resultado: `ag_cluster` → `Promoted lnx01`, `Unpromoted lnx02 bkp01`; `virtualip Started lnx01`; `ens18` de LNX01 con 192.168.202.28/22 y 192.168.202.27/22.

**Pendiente (hecho el 26/11, apartado 2.3.9):** base de datos de prueba en el AG, pruebas de conmutación y firewall de los Linux.

**Capturas** (prefijo `2026-11-24_sesion03_`): `*_cluster-tras-reinicio`, `*_ufw-puertos`, `lnx01_error-fecha-certificado`, `lnx01_certificado-creado`, `lnx01_ficheros-certificado`, `lnx01_cert-a-tmp`, `lnx01_scp-certificado`, `lnx01_borrar-tmp`, `lnx02/bkp01_mover-certificado`, `lnx02/bkp01_ficheros-certificado`, `lnx02_crear-certificado`, `bkp01_master-key`, `bkp01_crear-certificado`, `lnx02/bkp01_certificado-importado`, `*_endpoint`, `*_puerto-5022`, `lnx01_crear-ag`, `lnx02/bkp01_join-ag`, `lnx01_replicas-ag`, `*_login-pacemaker`, `lnx01_fichero-passwd`, `*_prueba-pacemakerlogin`, `*_agente-mssql`, `lnx01_pcs-status-ag`, `lnx01_crear-vip-reglas`, `lnx01_pcs-status-vip`.

### 2.3.9 Sesión 4 (26/11): base de datos en el AG, web en alta disponibilidad y firewall

**1. Estado al encender.** El clúster se forma solo, pero la réplica principal sale en **lnx02** y la VIP con ella. Pacemaker no tiene preferencia entre LNX01 y LNX02 (son iguales) y promueve la que está lista primero. **Decisión (Max): no se pone preferencia de nodo**; con `prefers lnx01`, cada vez que LNX01 volviera tras una caída habría otro corte de unos 30 s. Desde aquí se trabaja **por la VIP .27**, que siempre lleva a la principal:

```bash
sqlcmd -S 192.168.202.27 -U sa -C -W -Q "SELECT @@SERVERNAME AS servidor; SELECT ar.replica_server_name, rs.role_desc, rs.connected_state_desc, rs.synchronization_health_desc FROM sys.availability_replicas ar JOIN sys.dm_hadr_availability_replica_states rs ON ar.replica_id = rs.replica_id;"
```

Con el AG vacío, lnx01 y lnx02 salen `NOT_HEALTHY` (la salud se calcula con las bases de datos); con una base de datos dentro pasan a `HEALTHY`.

**2. Base de datos de prueba `cibernova_pruebas` en el AG:**

```bash
# En la secundaria (permite el seeding automático; en BKP01 no, porque no guarda datos)
sqlcmd -S localhost -U sa -C -Q "ALTER AVAILABILITY GROUP [sqlag_cibernova] GRANT CREATE ANY DATABASE;"
# Por la VIP (en la principal): recuperación completa y copia completa, obligatorias para entrar en un AG
sqlcmd -S 192.168.202.27 -U sa -C -Q "CREATE DATABASE cibernova_pruebas; ALTER DATABASE cibernova_pruebas SET RECOVERY FULL; BACKUP DATABASE cibernova_pruebas TO DISK = N'/var/opt/mssql/data/cibernova_pruebas.bak';"
sqlcmd -S 192.168.202.27 -U sa -C -Q "ALTER AVAILABILITY GROUP [sqlag_cibernova] ADD DATABASE cibernova_pruebas;"
# En la secundaria: ONLINE, SYNCHRONIZED, HEALTHY
sqlcmd -S localhost -U sa -C -W -Q "SELECT name, state_desc FROM sys.databases WHERE name = 'cibernova_pruebas'; SELECT DB_NAME(database_id) AS bbdd, synchronization_state_desc, synchronization_health_desc FROM sys.dm_hadr_database_replica_states WHERE is_local = 1;"
```

Tabla `dbo.prueba_ha (id IDENTITY, servidor SYSNAME, fecha DATETIME2)`: cada escritura guarda `@@SERVERNAME`, para ver después de cada conmutación que los datos siguen.

**3. Conmutación manual.** Siempre con Pacemaker, nunca con `ALTER AVAILABILITY GROUP ... FAILOVER` (con `CLUSTER_TYPE = EXTERNAL` manda Pacemaker; si se conmutara desde SQL Server, la VIP se quedaría en el nodo equivocado):

```bash
sudo pcs resource move ag_cluster-clone lnx01 --promoted
sudo pcs constraint location      # vacío: esta versión de pcs borra sola la restricción temporal (cli-prefer)
```

**4. Prueba de caída de LNX01 (PR-04, BBDD).** Con LNX01 principal: `ping -D 192.168.202.27` en una consola de PROC y `qm stop 128` en otra (corte de corriente). Secuencia observada:

1. lnx01 `OFFLINE`, ninguna réplica `Promoted`, VIP `Stopped` (estado intermedio correcto: Pacemaker no promueve hasta haber hecho *fencing*, para no tener dos principales).
2. `pcs stonith history` → `reboot of lnx01 successful: delegate=bkp01 ... 17:34:34`.
3. `Promoted lnx02`, VIP y escrituras en LNX02; LNX01 vuelve sola (reiniciada por `fence_pve`, `qm status 128` → `running`) como secundaria `SYNCHRONIZED/HEALTHY`.

Resultado: **≈ 36 s sin servicio** (36 de 189 pings perdidos, uno por segundo) y **0 datos perdidos** (commit síncrono).

**5. Apache + PHP-FPM** (en LNX01 y LNX02):

```bash
sudo apt update && sudo apt install -y apache2 php8.3-fpm php8.3-cli php8.3-dev php-pear
sudo pecl install sqlsrv pdo_sqlsrv
printf "; priority=20\nextension=sqlsrv.so\n" | sudo tee /etc/php/8.3/mods-available/sqlsrv.ini
printf "; priority=30\nextension=pdo_sqlsrv.so\n" | sudo tee /etc/php/8.3/mods-available/pdo_sqlsrv.ini
sudo phpenmod -v 8.3 sqlsrv pdo_sqlsrv && sudo systemctl restart php8.3-fpm
sudo a2enmod proxy_fcgi setenvif && sudo a2enconf php8.3-fpm && sudo systemctl reload apache2
php-fpm8.3 -m | grep -i sqlsrv && apachectl -M 2>/dev/null | grep proxy_fcgi
```

Versiones: Apache 2.4.58 (`mpm_event`), PHP 8.3.6 (FPM), `sqlsrv`/`pdo_sqlsrv` 5.13.3. `pdo_sqlsrv` con prioridad 30 para cargarse después de `pdo`. Los avisos de `pecl` sobre `php.ini` son normales (se activan con `mods-available`).

**6. Apache como recurso de Pacemaker (opción A).** Un solo Apache activo, siempre con la VIP y la réplica principal:

```bash
# En LNX01 y LNX02: solo Pacemaker arranca Apache (PHP-FPM sigue activo en los dos)
sudo systemctl disable --now apache2
# Una sola vez, desde cualquier nodo (la configuración del clúster es común)
sudo pcs resource create apache ocf:heartbeat:apache configfile=/etc/apache2/apache2.conf statusurl="http://localhost/server-status" op monitor interval=20s timeout=20s --disabled
sudo pcs constraint colocation add apache with virtualip INFINITY
sudo pcs constraint order virtualip then apache
sudo pcs constraint location apache avoids bkp01
sudo pcs resource enable apache
```

| Opción | Descripción | Decisión |
|---|---|---|
| **A** | Apache solo en el nodo de la VIP | **Elegida (Max):** un único servidor web activo, reglas sencillas, coincide con el diseño |
| B | Apache clonado en LNX01 y LNX02 | Descartada: más reglas y dos Apache que vigilar para ganar ≈ 1 s |
| C | Apache fuera de Pacemaker (systemd) | Descartada: un Apache caído no se detectaría y la VIP podría quedarse en un nodo sin web |

Se usa `ocf:heartbeat:apache` y no `systemd:apache2` porque pide `server-status` cada 20 s y detecta un Apache colgado, no solo uno parado. El recurso se crea `--disabled` para que no arranque en cualquier nodo antes de tener sus reglas. `avoids bkp01` es redundante con la colocación (la VIP nunca va a BKP01), pero lo deja explícito.

**7. Desglose de una conmutación planificada** (`journalctl -u pacemaker` en los dos nodos):

| Hora | Nodo | Acción | Tiempo |
|---|---|---|---|
| 18:03:01 | — | La web deja de responder | — |
| 18:03:03 | lnx02 | `stop` de apache y virtualip | 2 s |
| 18:03:06 | lnx02 | `demote` de `ag_cluster` | 3 s |
| 18:03:28 | lnx01 | `promote` de `ag_cluster` | **22 s** |
| 18:03:34 | lnx01 | `start` de virtualip | 6 s (notificaciones `notify=true`) |
| 18:03:35 | lnx01 | `start` de apache | 1 s |
| 18:03:36 | — | La web vuelve | **≈ 35 s** |

El 63 % del corte es la promoción del AG: el agente `ocf:mssql:ag` comprueba que la nueva principal tiene todas las transacciones confirmadas (es lo que garantiza RPO 0). Ajustar sus tiempos queda como posible mejora de la Fase 3 (menos espera = más riesgo de promover una réplica atrasada).

**8. Usuario de SQL Server para la web (`web_cibernova`).** La web no usa `sa`: tiene un *login* propio que solo lee y escribe en su base de datos. Los *logins* son de la instancia y **no viajan con el AG**; el usuario de la base de datos sí, y va enlazado al *login* por su SID. Por eso el *login* se crea en las dos réplicas **con el mismo SID** (si no, tras una conmutación el usuario quedaría huérfano y la web no entraría):

```sql
-- LNX01 (sqlcmd interactivo: la contraseña no queda en el historial)
CREATE LOGIN web_cibernova WITH PASSWORD = '...', CHECK_POLICY = ON;
SELECT name, sid FROM sys.sql_logins WHERE name = 'web_cibernova';   -- 0x4A0196600703D245B4146ECB2C1553E9
-- LNX02, con la misma contraseña y el mismo SID
CREATE LOGIN web_cibernova WITH PASSWORD = '...', SID = 0x4A0196600703D245B4146ECB2C1553E9, CHECK_POLICY = ON;
-- Por la VIP: usuario en la base de datos (lo replica el AG)
CREATE USER web_cibernova FOR LOGIN web_cibernova;
ALTER ROLE db_datareader ADD MEMBER web_cibernova;
ALTER ROLE db_datawriter ADD MEMBER web_cibernova;
```

En BKP01 no se crea (no guarda datos y la web no se conecta a ella). Mejora prevista: usar `svc_web` del dominio (autenticación de AD con *keytab*) cuando los DC estén en Proxmox.

**9. Página de prueba `bbdd.php`** (en LNX01 y LNX02; ficheros en [`configs/linux/web/`](../../configs/linux/web/)). Las credenciales van en `/etc/cibernova/web.ini` (`640 root:www-data`), **fuera de la carpeta web**: aunque Apache enseñara el código, la contraseña no saldría. La conexión es por la **VIP**. Si falla, el usuario solo ve un mensaje genérico y el detalle va al registro. **Riesgo aceptado:** `TrustServerCertificate=yes` (el certificado de SQL Server es autofirmado; Fase 3: certificado propio). El contenido de los dos nodos se copia a mano y se comprueba con `ls -l` (WEB-03: falta elegir método para la aplicación definitiva).

**10. Conmutación con toda la cadena** (VIP → Apache → PHP → SQL Server). En PROC:

```bash
while true; do r=$(curl -s -m 2 http://192.168.202.27/bbdd.php | sed -n '1p;3p' | tr '\n' ' '); echo "$(date +%T) ${r:-SIN RESPUESTA}"; sleep 1; done
```

y `sudo pcs resource move ag_cluster-clone lnx02 --promoted`. Última respuesta de lnx01 a las 18:36:15 (fila 2013), primera de lnx02 a las 18:36:44 (fila 3002): **≈ 29 s sin servicio, ninguna fila perdida**.

**Saltos de `IDENTITY`** (2 → 1002 → 2002, 2013 → 3002): SQL Server reserva los valores de 1000 en 1000 en memoria y descarta los no usados al conmutar. **Decisión (Max): se mantiene la caché** y se documenta; `IDENTITY_CACHE = OFF` haría las escrituras más lentas y una aplicación no debe depender de números seguidos.

**11. Firewall `ufw`** (LNX01 y BKP01; LNX02 en la sesión 5). Se activa de nodo en nodo, empezando por uno sin la réplica principal y comprobando `pcs status` después de cada uno (un error en Corosync haría que Pacemaker reiniciara el nodo):

```bash
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow from 192.168.200.0/22 to any port 22 proto tcp comment 'SSH administracion'
sudo ufw allow 80/tcp comment 'Web'          # solo en LNX01 y LNX02
for ip in 192.168.202.28 192.168.202.29 192.168.202.30; do sudo ufw allow from $ip to any port 5405 proto udp comment 'Corosync'; sudo ufw allow from $ip to any port 2224 proto tcp comment 'pcsd'; sudo ufw allow from $ip to any port 5022 proto tcp comment 'AG endpoint'; sudo ufw allow from $ip to any port 1433 proto tcp comment 'SQL Server'; done
sudo ufw show added        # comprobar la regla del 22 antes de activar
sudo ufw enable && sudo ufw status numbered
```

| Puerto | Servicio | Origen permitido |
|---|---|---|
| 22/tcp | SSH (y SFTP más adelante) | 192.168.200.0/22 |
| 80/tcp | Web | Cualquiera (solo LNX01 y LNX02) |
| 5405/udp | Corosync (knet) | .28, .29, .30 |
| 2224/tcp | `pcsd` | .28, .29, .30 |
| 5022/tcp | *Endpoint* del AG | .28, .29, .30 |
| 1433/tcp | SQL Server (DB-06) | .28, .29, .30 |

No se abren 3121 (Pacemaker Remote) ni 21064 (DLM), previstos el 24/11, porque no se usan. Resultado: LNX01 con 15 reglas, BKP01 con 13; clúster y web sin cambios. La web entra en SQL Server por la VIP local (interfaz `lo`, que `ufw` permite siempre).

**Por qué `ufw` y no OPNsense en la Fase 1:** OPNsense solo filtra lo que pasa a través de él, y en la red plana los servidores hablan directamente; habría que segmentar la red, cambiar la IP de todas las VMs y montar 2 OPNsense en HA con unas 3 direcciones más del aula, que no quedan libres. Se mantiene la decisión del 16/11 (firewall en cada servidor) y OPNsense con VLAN queda para la Fase 3 [PENDIENTE DE CONFIRMAR si lo pidió el profesorado].

**Al terminar:** `sudo pcs cluster stop --all` (para que no se dispare una conmutación al apagar el nodo principal) y `qm shutdown 128 && qm shutdown 129 && qm shutdown 130`. Réplica principal, VIP y Apache en **lnx02**.

**Capturas** (prefijo `2026-11-26_sesion04_`, 66 en `capturas-sesion04.zip`): `lnx01_pcs-status-inicial`, `lnx01_ag-estado-por-vip`, `lnx01_grant-create-any-database`, `lnx01_bbdd-creada-backup`, `lnx01_bbdd-anadida-ag`, `lnx01_bbdd-sincronizada`, `lnx01_datos-prueba-lnx02`, `lnx01_ag-healthy`, `lnx01_pcs-move-lnx01`, `lnx01_constraints-tras-move`, `lnx01_datos-tras-conmutacion`, `proc_ping-vip-inicio`, `proc_qm-stop-128`, `lnx02_pcs-status-caida-lnx01`, `proc_ping-vip-corte`, `proc_ping-vip-resumen`, `lnx02_pcs-status-tras-caida`, `lnx02_stonith-history`, `lnx02_datos-tras-caida`, `proc_qm-status-128`, `lnx02_lnx01-resincronizada`, `lnx0X_apache-php-instalado`, `lnx0X_pecl-sqlsrv`, `lnx0X_drivers-so`, `lnx0X_sqlsrv-ini`, `lnx0X_pdo-sqlsrv-ini`, `lnx0X_php-sqlsrv`, `lnx0X_nodo-php`, `lnx0X_apache-disabled`, `lnx02_pcs-apache-creado`, `proc_curl-vip-nodo`, `lnx02_pcs-move-web`, `proc_curl-bucle-conmutacion`, `lnx0X_journal-tiempos-conmutacion`, `lnx01_login-web`, `lnx02_login-web-mismo-sid`, `lnx02_usuario-bbdd-web`, `lnx01_web-ini`, `lnx0X_web-ini-permisos`, `lnx_bbdd-php-codigo`, `proc_curl-bbdd-php`, `lnx0X_ficheros-web`, `proc_bucle-cadena-completa`, `lnx01_pcs-move-lnx02`, `lnx01_ufw-*`, `lnx02_pcs-status-tras-ufw-lnx01`, `bkp01_ufw-*`, `proc_curl-bbdd-ufw`, `lnx02_pcs-status-ufw-final`.

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

### 2.6 FS01: instalación y configuración base en VirtualBox (23/11, Oriol)

FS01 se construye en VirtualBox, en el mismo equipo que los DC y con adaptador puente, para poder unirla al dominio y configurarla en casa. Capturas en la memoria del proyecto (Google Doc), apartado "Instalación de FS01".

**Recursos:** 2 vCPU, 4 GB de RAM, disco de sistema de 50 GB y **disco de datos aparte de 150 GB reservado dinámicamente** (justificación en el diseño, apartado 3.8: la suma de las cuotas personales es de 232 GB y se sobreasigna).

**1. Nombre, red y comprobaciones previas (PowerShell):**
```powershell
Set-TimeZone -Id "Romance Standard Time"; Rename-Computer -NewName FS01 -Restart
$if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.25 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23,192.168.202.24
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.cibernova.local   # dc01 (.23) y dc02 (.24)
w32tm /stripchart /computer:192.168.202.23 /samples:3              # diferencia de 0,2 s
```

**2. Unión al dominio.** `Add-Computer` falló porque se cerró la ventana de la credencial (*"No se puede enlazar el argumento al parámetro 'Credential' porque es nulo"*). Se hizo por interfaz gráfica:
- En DC01: `dsa.msc` → `CiberNova` → `Servidores` → Nuevo → Equipo → `FS01` (**cuenta preconfigurada**: la interfaz gráfica no deja elegir la OU y, sin esto, FS01 acabaría en `Computers` sin las GPO de servidores).
- En FS01: `sysdm.cpl` → Cambiar → Dominio `cibernova.local` → credencial `Administrador@cibernova.local` → reinicio.
- Comprobación: `Test-ComputerSecureChannel` → `True`; `gpresult /r /scope computer` → `CN=FS01,OU=Servidores,OU=CiberNova,...` con `GPO_Servidores_Auditoria`, `Default Domain Policy`, `GPO_Dominio_CuentasServicio` y `GPO_Dominio_Firewall`.

**3. Roles (Administrador del servidor → Agregar roles y características):** Servidor de archivos, Espacios de nombres DFS, Replicación DFS y Administrador de recursos del servidor de archivos, con sus herramientas. Comprobación: `Get-WindowsFeature FS-FileServer, FS-DFS-Namespace, FS-DFS-Replication, FS-Resource-Manager` → `Installed`.

**4. Espacio de nombres (Administración de DFS → Nuevo espacio de nombres):** servidor FS01, nombre `empresa` (nombre fijado por el Anexo I), raíz `C:\DFSRoots\empresa` con permisos "administradores control total, resto solo lectura", **basado en dominio** y **modo Windows Server 2008**. Después, Propiedades → Avanzadas → **Habilitar la enumeración basada en el acceso**. Comprobación: `Get-DfsnRoot` → `Domain V2`, `Online`, `Flags: Site Costing, AccessBased Enumeration`; `Get-DfsnRootTarget` → `\\FS01.cibernova.local\empresa` `Online`.

**5. Disco de datos (Administración de discos):** inicializar en **GPT** (estándar actual, admite más de 2 TB), nuevo volumen simple **NTFS**, letra **D:**, etiqueta **`Datos`**.

**6. Recursos compartidos ocultos con ABE:** carpetas `D:\Datos\Personales`, `Departamentos`, `Proyectos` y `Comun`. `Personales$` por interfaz gráfica (Nuevo recurso compartido → SMB rápido → marcar *Habilitar la enumeración basada en el acceso* → Personalizar permisos → pestaña *Compartir*: quitar *Todos* y dar Control total a *Usuarios autentificados*; la pestaña *Permisos* (NTFS) no se toca). Los otros tres por PowerShell:
```powershell
$au=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-11').Translate([System.Security.Principal.NTAccount]).Value; foreach ($c in 'Departamentos','Proyectos','Comun') { New-Item -ItemType Directory -Force -Path "D:\Datos\$c" | Out-Null; New-SmbShare -Name ($c + '$') -Path "D:\Datos\$c" -FullAccess $au -FolderEnumerationMode AccessBased }
```
(El SID S-1-5-11 es *Usuarios autentificados*; así funciona con Windows en castellano.) Comprobación: `Get-SmbShare` y `Get-SmbShareAccess` → los cuatro `AccessBased` y una sola entrada `NT AUTHORITY\Usuarios autentificados · Full`.

**Decisiones:** cuatro recursos en lugar de uno y permisos abiertos en el recurso con los reales en NTFS (diseño, apartado 3.8; bitácora del 23/11). Los permisos NTFS se aplicarán con `06-carpetas-permisos.ps1` (matriz P-01 a P-44).

**7. Carpetas del espacio de nombres (24/11, por interfaz gráfica):** Administración de DFS → `\\cibernova.local\empresa` → Nueva carpeta: `Comun`, `Departamentos`, `Personales` y `Proyectos`, cada una con destino `\\FS01\<Carpeta>$`, sin grupo de replicación (se crea con FS02). Comprobación (`Get-DfsnFolderTarget` no admite comodines: error 1168):
```powershell
Get-DfsnFolder -Path "\\cibernova.local\empresa\*" | ForEach-Object { Get-DfsnFolderTarget -Path $_.Path }   # las cuatro Online
```

**8. Replicación con DC02 (24/11):** en DC01, `repadmin /syncall /AdeP` y `repadmin /replsummary` → 0 errores en las dos direcciones. En DC02, `Get-ADComputer FS01` → `OU=Servidores` y `Get-DfsnRoot` → `\\cibernova.local\empresa` `Online`: el espacio de nombres ya no depende solo de DC01. (Si se ponen dos comandos con objetos distintos en la misma línea, PowerShell muestra el segundo en blanco: ejecutarlos por separado.)

**Pendiente en FS01:** subcarpetas del Anexo I, grupos `DL_` y permisos NTFS, SACL de auditoría, cuotas FSRM, prioridad en las referencias e importación en Proxmox (VMID 125). DFS-R con FS02: hecha (apartado 2.7).

### 2.7 FS02 y replicación DFS-R (24/11, sesión 3, Oriol)

FS02 se construye igual que FS01 (apartado 2.6), en VirtualBox y en el mismo equipo que los DC. **Instalación limpia desde la ISO**: un clon de FS01 tendría el mismo SID y daría problemas en el dominio. Mismos recursos que FS01 (2 vCPU, 4 GB, 50 GB de sistema y 150 GB de datos), porque es su pareja y debe poder asumir toda la carga.

**1. Red y dominio** (mismos comandos que FS01, con `FS02` y la IP `192.168.202.26`). La consulta `Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.cibernova.local` devuelve dc01 y dc02: Windows encuentra el dominio con esos registros, y salen los dos DC. Cuenta FS02 preconfigurada en DC01 en `OU=Servidores,OU=CiberNova` y unión por interfaz gráfica. `gpresult` → `CN=FS02,OU=Servidores,...` con las GPO de servidores.

**2. Roles** (los mismos cuatro que FS01, por interfaz gráfica) y **recursos compartidos** (una línea; carpetas vacías, el contenido llega por DFS-R):
```powershell
$au=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-11').Translate([System.Security.Principal.NTAccount]).Value; foreach ($c in 'Personales','Departamentos','Proyectos','Comun') { New-Item -ItemType Directory -Force -Path "D:\Datos\$c" | Out-Null; New-SmbShare -Name ($c + '$') -Path "D:\Datos\$c" -FullAccess $au -FolderEnumerationMode AccessBased }
```

**3. Segundo servidor del espacio de nombres** (Administración de DFS → `\\cibernova.local\empresa` → Agregar servidor de espacio de nombres → `FS02`, raíz `C:\DFSRoots\empresa`, administradores control total y resto solo lectura). La pestaña *Servidores de espacio de nombres* muestra FS01 y FS02 habilitados: la raíz ya no depende de un solo servidor.

**4. Replicación DFS-R:** en cada carpeta del espacio de nombres, *Agregar destino de carpeta* `\\FS02\<Carpeta>$` → *Sí* al grupo de replicación. Asistente: **FS01 como miembro principal** (en la replicación inicial manda su contenido; FS02 estaba vacía), **malla completa** y replicación **continua con ancho de banda completo**. Resultado: cuatro grupos de replicación, uno por carpeta (un problema en una no frena a las demás).

**5. Prueba:**
```powershell
Update-DfsrConfigurationFromAD                                                    # en FS01 y FS02: leer ya la configuración de AD
New-Item -Path "D:\Datos\Comun\prueba-replicacion.txt" -ItemType File -Value "Prueba DFS-R 24/11" -Force   # en FS01
Get-ChildItem D:\Datos\Comun                                                    # en FS02: aparece el fichero (16:51)
```

**6. FS01 con prioridad en las referencias (26/11, por interfaz gráfica).** En cada carpeta, destino `\\FS02\<Carpeta>$` → Propiedades → *Opciones avanzadas* → *Invalidar orden de referencia* → **Último de todos los destinos** (`GlobalLow`). Comprobación:
```powershell
Get-DfsnFolder -Path "\\cibernova.local\empresa\*" | ForEach-Object { Get-DfsnFolderTarget -Path $_.Path }
```
8 destinos `Online`: FS01 `sitecost-normal` y FS02 `global-low` 📸. **Por qué:** DFS-R no bloquea ficheros abiertos; si dos personas editaran el mismo fichero en FS01 y en FS02 a la vez, al replicar se perdería un cambio. Con FS02 al final, todos trabajan contra FS01 y FS02 solo se usa si FS01 cae. **Alternativa descartada:** *Último de los destinos de igual costo*: hoy funcionaría igual (un solo sitio de AD), pero dejaría de garantizar el orden si se crean sitios por sede. `Get-DfsnFolderTarget` no admite comodines (error 1168): por eso se encadena con `Get-DfsnFolder`.

**7. Borrado replicado y estado de DFS-R (26/11).** Se borra `prueba-replicacion.txt` en FS01 y desaparece en FS02 📸. Informe de estado (Administración de DFS → Replicación → Crear informe de diagnóstico): **0 errores**, 2 de 2 servidores; una advertencia ("el servicio se reinicia con frecuencia") explicada por los apagados del laboratorio, sin eventos de nivel Error en el registro *DFS Replication* 📸.

**Pendiente:** prueba de caída (PR-03) cuando haya un cliente.

---

### 2.8 Permisos, carpetas personales, perfiles y unidades de red (26–27/11, Oriol)

Todo en VirtualBox, con DC01, DC02, FS01 y FS02 encendidos. Los permisos y las carpetas se aplican en FS01 y llegan a FS02 por DFS-R.

#### 2.8.1 Matriz de permisos y modelo AGDLP

La matriz completa (P-01 a P-44, 50 carpetas, 63 grupos) está en [`08-matriz-permisos.md`](08-matriz-permisos.md), con las decisiones justificadas. Resumen:

- **AGDLP:** usuario → grupo global `G_<Departamento>` → grupo de dominio local `DL_<Carpeta>_<Nivel>` → permiso NTFS. Solo los `DL_` aparecen en las ACL. Nuevo grupo global `G_RRHH_Nominas_Consulta` (rosa.martinez, P-08): los permisos van siempre a grupos.
- **Niveles:** CT, M, C, L (listar solo la carpeta; con ABE cada uno ve solo lo que puede abrir), D (depósito con `CREATOR OWNER`), I (intercambio) y X (denegar, solo becarios en Proyectos).
- **En cada carpeta con la herencia cortada:** SYSTEM y Administradores con control total y **DERECHOS DE PROPIETARIO solo con "Permisos de lectura"** (quien crea un fichero no puede cambiarle los permisos: el nivel M del Anexo queda de verdad sin "cambiar permisos").
- **Validación previa:** simulación con los 89 usuarios del CSV: 0 errores y pruebas 1–8 y 13 correctas.

#### 2.8.2 Ejemplo manual: `RRHH\Nominas` por interfaz gráfica

Para entender el proceso antes de automatizarlo: grupos `G_RRHH_Nominas_Consulta`, `DL_RRHH_Nominas_M` y `DL_RRHH_Nominas_C` (seguridad) en DC01; en FS01, herencia deshabilitada, SYSTEM y Administradores CT, DERECHOS DE PROPIETARIO, los dos `DL_` (Modificar y Lectura y ejecución) y auditoría (Todos, éxito y error). **Acceso efectivo:** rosa.martinez solo lectura; irene.moreno (RRHH sin nóminas) sin acceso 📸.

**Incidencia:** al deshabilitar la herencia se eligió convertir los permisos heredados (quedaron *Usuarios* y *CREATOR OWNER*, que se quitaron) y las entradas de los `DL_` no se guardaron: Rosa salía sin ningún permiso. Diagnóstico: `Get-ADGroupMember` (AD correcto) e `icacls "D:\Datos\Departamentos\RRHH\Nominas"` (faltaban los `DL_`). Se volvieron a añadir.

`auditpol /get /subcategory:"Sistema de archivos"` en FS01 → **Aciertos y errores**: la GPO `GPO_Servidores_Auditoria` está aplicada y las SACL registran eventos 📸.

#### 2.8.3 Script `06-carpetas-permisos.ps1` y comprobación con el 96

En FS01, con el módulo de AD (`Install-WindowsFeature RSAT-AD-PowerShell`):
```powershell
powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1 -Simular   # no cambia nada
powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1            # 63 DL_, 50 carpetas, 50 ACL, 3 auditorías
powershell -ExecutionPolicy Bypass -File .\96-comprobar-carpetas-permisos.ps1  # en FS01 y en FS02: 0 errores
```
El script es **idempotente** (rehace las reglas explícitas según el plan; lo hecho a mano en Nominas lo deja igual) y trabaja con SID, sin tocar el propietario. **Incidencias:**
- v1.0 → *No se encuentra ninguna sobrecarga para FileSystemAccessRule*; v1.1 y v1.2 → *No se puede convertir a NULL ... FileSystemRights*. **Causa:** PowerShell no distingue mayúsculas en las variables, y el bucle `foreach ($r in $Recursos)` sobrescribía `$R` (el tipo de los permisos). **v1.3:** nombres distintos (`$FSR`, `$Rec`). Los intentos fallidos se pararon antes de cambiar ningún permiso.
- El 96 v1.1 daba un falso error en `Comun\Intercambio`: Windows añade *Synchronize* a la regla de crear (`icacls` → `(S,WD,AD)`). La v1.2 compara la suma de derechos de cada grupo.
- En FS02, el 96 falló la primera vez porque faltaba el módulo de AD; aun así ya se veían las reglas de los `DL_`, replicadas por DFS-R.

#### 2.8.4 Carpetas personales, unidad H:, perfiles móviles y cuotas (script 07)

`07-personales-cuotas-perfiles.ps1` (en FS01, con el CSV al lado; en FS02 con `-SoloCuotas`):
- **89 carpetas** `Personales\<usuario>`: solo el usuario con Modificar (única excepción a AGDLP, porque la carpeta es suya), SYSTEM y Administradores CT (acceso técnico y copias), DERECHOS DE PROPIETARIO solo lectura de permisos. Ni su responsable ni Dirección entran; ABE oculta las de los demás.
- **H:** en la cuenta de AD (`HomeDrive`/`HomeDirectory` = `\\cibernova.local\empresa\Personales\<usuario>`).
- **Perfil móvil** (`ProfilePath` = `\\cibernova.local\empresa\Perfiles\<usuario>`) para los 16 empleados con perfil "Movil" (Dirección y Comercial).
- **`Perfiles$`** (`D:\datos\Perfiles`, ABE, sin caché sin conexión) con los permisos que recomienda Microsoft: Usuarios autentificados solo pueden crear su carpeta en la raíz y `CREATOR OWNER` tiene control total dentro de la suya.
- **Cuotas FSRM:** plantillas `CiberNova personal 2 GB`, `5 GB` y `500 MB` con límite estricto y aviso al 90 % (evento de advertencia en el registro de Aplicación): 65 × 2 GB, 20 × 5 GB, 4 × 500 MB en FS01 y en FS02 (las cuotas no se replican con DFS-R) 📸. El aviso por correo necesitaría un servidor SMTP [PENDIENTE DE CONFIRMAR si basta con el evento].
- **Pendiente [PENDIENTE DE CONFIRMAR con Max]:** el Anexo pide que la carpeta personal la cree el script de alta; propuesta: que el 02 (v2.3) llame al 07 en cada alta.

**Perfiles en DFS:** `Perfiles$` también en FS02 y carpeta `Perfiles` en `\\cibernova.local\empresa` con destinos FS01 y FS02, grupo de replicación (FS01 principal, malla completa) y FS02 como último destino. **Por qué:** los perfiles móviles también deben ser redundantes, y Microsoft solo admite perfiles sobre DFS-R si se usa un único destino a la vez, que es lo que garantiza la prioridad de FS01.

#### 2.8.5 GPO de unidades de red y de redirección de carpetas

- **`GPO_Usuarios_Unidades`** (vinculada a la OU CiberNova; Configuración de usuario → Preferencias → Asignaciones de unidad; acción *Actualizar*, volver a conectar y **destino de nivel de elemento por grupo**): **G:** `\\cibernova.local\empresa\Departamentos` (`G_Sede_Barcelona` O `G_Sede_Madrid` O `G_Sede_Valencia`), **P:** `...\Proyectos` (`DL_Proyectos_L`: solo quien tiene algún proyecto) y **S:** `...\Comun` (`DL_Comun_C`: empleados y recepción) 📸. La H: va en la cuenta de AD.
- **`GPO_Usuarios_Redireccion`** (OU CiberNova): filtrado de seguridad solo `G_Sede_*`; *Usuarios autentificados* con Leer (necesario para procesar la GPO); `G_Direccion` y `G_Comercial` con **Denegar** "Aplicar directiva de grupo" (tienen perfil móvil) 📸. Documentos y Escritorio → `\\cibernova.local\empresa\Personales\%USERNAME%\Documentos` y `\Escritorio`, **sin derechos exclusivos** (si no, Windows cambiaría los permisos de la carpeta personal) y moviendo el contenido. Al guardar, Windows lo convierte en "Crear una carpeta para cada usuario en la ruta raíz" con raíz `...\Personales`, que es equivalente 📸. Incidencia: un punto al final de la ruta de Escritorio, corregido.
- **Pendiente:** perfil obligatorio de `recepcion.bcn` (necesita un cliente) y comprobar unidades, redirección y perfil móvil desde CLI01/CLI02 (pruebas 9, 10 y 12 del Anexo I).

#### 2.8.6 Hora del dominio

Las VM tenían horas distintas. Se configura la jerarquía de hora del dominio (Kerberos falla con más de 5 minutos de diferencia):
```powershell
# DC01 (emulador de PDC): hora oficial de España
tzutil /s "Romance Standard Time"; w32tm /config /manualpeerlist:"hora.roa.es,0x8 es.pool.ntp.org,0x8" /syncfromflags:manual /reliable:yes /update; Restart-Service w32time; w32tm /resync /rediscover
# DC02, FS01 y FS02: desde el dominio
tzutil /s "Romance Standard Time"; w32tm /config /syncfromflags:domhier /update; Restart-Service w32time; w32tm /resync /force
```
Comprobado en FS02: `w32tm /query /source` → `DC01.cibernova.local`. En Proxmox habrá que comprobar si la red del aula deja pasar NTP (UDP 123) [PENDIENTE DE CONFIRMAR].

#### 2.8.7 Exportación de los Windows a OVA (27/11)

Con todo lo anterior hecho, se exportan a OVA las máquinas Windows de VirtualBox (DC01, DC02, FS01 y FS02 [PENDIENTE DE CONFIRMAR que son las cuatro]), a la espera de importarlas en Proxmox (VMID 123–126) con el procedimiento del apartado 2.2 (de una en una, DC01 primero, borrando cada OVA de `local` después). **Desde la exportación, las copias de VirtualBox no se tocan:** los cambios no llegarían a Proxmox y, en los DC, encender una copia antigua después de importar rompería la replicación (*USN rollback*, apartado 2.4).

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

**Riesgo aceptado (17/11/2026):** durante el montaje (Fases 1 y 2) se usan contraseñas sencillas para poder recordarlas. Al empezar la Fase 3 se cambian todas y se guardan en un gestor de contraseñas (KeePassXC o Proton Pass, **[PENDIENTE DE CONFIRMAR]**). La red del aula es compartida con otros grupos, así que no se reutiliza la misma contraseña en todas las máquinas. Propuesta: mantener desde ya un inventario de **dónde** se usa cada credencial (nunca la contraseña): `admincibernova` en cada Ubuntu, `hacluster` (Pacemaker), usuario de `fence_pve` en Proxmox, `sa`, `pacemakerLogin` y `web_cibernova` (este también en `/etc/cibernova/web.ini` de LNX01 y LNX02) en SQL Server, `svc_backup` (Bareos).

---

## 7. Pendiente

> La lista completa y ordenada está en [`docs/gestion/lista-tareas-fase1.md`](../gestion/lista-tareas-fase1.md). Aquí solo se resume lo inmediato de las VMs ya construidas.

- [x] Ejecutar el script 02 v2.2 en DC01 y hacer las capturas (16/11).
- [ ] Exportar DC01 a OVA, importarlo en Proxmox y comprobar red, DNS (`dcdiag /test:dns`) y rendimiento (pasa a la sesión 2, D-05).
- [x] Crear DC02 (instalación limpia, no clon de DC01), promoverlo y comprobar la replicación (`repadmin /replsummary`): 19/11, en VirtualBox.
- [ ] Exportar DC01 y DC02 a OVA e importarlos en Proxmox (123 y 124, DC01 primero). **OVA exportadas el 27/11** (también FS01 y FS02); falta importar.
- [x] LNX01 instalada en VirtualBox y exportada a OVA (17/11, apartado 2.3.1).
- [x] Importar LNX01 en Proxmox (VMID 128, 17/11). WEB01 y las demás VMs antiguas, borradas.
- [x] Netplan fijo de LNX01 con DNS públicos (17/11).
- [x] SQL Server 2025 instalado en LNX01 (sin configurar). LNX02 clonada y personalizada (17/11).
- [x] Personalizar BKP01 (.30, 18/11) y crear BKP02 (131, .31, 19/11, desde `base-limpia`).
- [x] `mssql-conf setup` en LNX01, LNX02 (Enterprise Developer) y BKP01 (Express); `hadr.hadrenabled` activado en las tres y Agente en LNX01/LNX02 (19/11).
- [x] Pacemaker + Corosync (`cibernova-g3`) de 3 nodos y fencing con `fence_pve`, probado (23/11, apartado 2.3.7).
- [x] AG de SQL Server `sqlag_cibernova` (certificados, *endpoints*, réplica de solo configuración en BKP01), recursos de Pacemaker y VIP .27 (24/11, apartado 2.3.8).
- [x] Base de datos de prueba en el AG y pruebas de conmutación manual y de caída (26/11, apartado 2.3.9; punto de control del 1/12 cumplido).
- [x] Apache + PHP-FPM con `sqlsrv` en LNX01/LNX02 y Apache en Pacemaker con la VIP (26/11, apartado 2.3.9).
- [ ] Firewall `ufw` en LNX02 (LNX01 y BKP01 hechos el 26/11) y BKP02.
- [ ] SFTP con *chroot* en LNX01 y LNX02 y prueba de caída.
- [ ] Aplicación web definitiva (WEB-01) y método para copiar el contenido a los dos nodos (WEB-03).
- [ ] **Todo subido a GitHub antes del 4/12/2026** (cierre del repositorio).
- [x] OU Equipos y Servidores: script 01 v2.1 ejecutado en DC01, 23 OU (16/11).
- [x] Ejecutar `03-cuentas-especiales.ps1` en DC01: 26 comprobaciones OK (16/11).
- [ ] Caducidad de `auditor.ext` cuando se sepa el fin de la Fase 3.
- [ ] GPO pendientes: privilegio de copia para `svc_backup` y perfil obligatorio de `recepcion.bcn`. ~~Perfil móvil, redirección y unidades de red~~ (configurados el 26/11, apartado 2.8.5; falta probarlos desde un cliente).
- [x] Carpetas personales, cuotas y perfiles (26/11, script 07, apartado 2.8.4). Falta que las cree el script de alta (02 v2.3) [PENDIENTE DE CONFIRMAR].
- [x] Configurar el DNS de DC01 (script 04, 17/11; deshecho con el 84 y rehecho por la interfaz gráfica el 18/11; reenviadores 8.8.8.8 y 1.1.1.1).
- [x] GPO de seguridad (script 05 v1.1, 18/11): 25 OK.
- [ ] Unir todas las máquinas al dominio ([guía 07](07-guia-dominio-dc02-union.md)). **FS01 unida el 23/11** (apartado 2.6) y **FS02 el 24/11** (apartado 2.7).
- [x] FS01 en VirtualBox: disco de datos, roles, espacio de nombres con ABE y cuatro recursos compartidos (23/11, apartado 2.6).
- [x] FS01 y FS02: carpetas DFS (24/11), DFS-R, prioridad de referencias, permisos NTFS con la matriz (script 06), auditoría y cuotas (26/11, apartados 2.7 y 2.8).
