# Memoria técnica de la infraestructura desplegada – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Versión:** 0.4 · 17/11/2026 (sesión 1)

> Documento vivo: se amplía al terminar cada servicio. Lo marcado con **[PENDIENTE DE CONFIRMAR]** hay que verificarlo.

---

## 1. Estado actual (17/11/2026)

| VM | Estado | Dónde está | Notas |
|---|---|---|---|
| Host Proxmox | Instalado (Proxmox VE 9.2.21, nodo `PROC`) | Servidor físico (192.168.202.3) | Ver [guía del hipervisor](02-guia-instalacion-hipervisor.md) |
| DC01 | **Completo** (16/11). **No se importó el 17/11 (D-05)**: bosque `cibernova.local`, DNS con reenviador, 23 OU, 27 grupos, 89 empleados, 6 cuentas adm., 6 cuentas especiales y políticas de contraseña. Capturas en la memoria | **VirtualBox** (exportar a OVA e importar en Proxmox el 17/11) | |
| DC02 | **Sin montar** (no promovido a DC) | — | Ver precauciones del apartado 2.4 antes de crearlo |
| LNX01 | **Proxmox (VMID 128)**: Ubuntu 24.04.5, IP .28 fija, DNS públicos, SQL Server 2025 instalado sin configurar | **Proxmox** | Importación manual (el asistente falló). Apartado 2.3 |
| LNX02 | **Proxmox (VMID 129)**: clon de LNX01 personalizado, IP .29, SQL Server sin configurar | Proxmox | Apartado 2.3.4 |
| BKP01 | **Proxmox (VMID 130)**: clonada, **sin personalizar** (tiene `lnx01` y .28 dentro) | Proxmox | Personalizar en la sesión 2 |
| BKP02 | No existe | — | Clon sin SQL Server (sesión 2) |
| FS01, FS02, clientes | Sin crear | — | — |

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

**Conclusión:** el router del aula da salida a Internet al rango .23–.33, pero **no contesta a las consultas DNS**. Es la misma causa del FAIL del reenviador en el `dcdiag` de DC01. **Solución:** `nameservers: addresses: [8.8.8.8, 1.1.1.1]` en netplan (sin 192.168.200.254: si se deja el primero, cada consulta espera varios segundos). Cuando DC01/DC02 estén en Proxmox, los Linux pasan a .23/.24 y los DC reenvían a 8.8.8.8/1.1.1.1 **[PENDIENTE DE CONFIRMAR]**.

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

Estado el 17/11: **LNX02 personalizada** (`machine-id` 95ec319c…, IP .29). **BKP01 clonada sin personalizar** (dentro tiene `lnx01` y .28: no arrancarla con LNX01 encendida). Los clones completos ocupan el disco entero en el thin pool (`Data% 100`); propuesta: `discard=on` y `fstrim -av` **[PENDIENTE DE CONFIRMAR]**.

**Capturas:** `lnx01_repos-microsoft`, `lnx01_mssql-instalado`, `proxmox_qm-list-lvs-clones`, `lnx02_personalizado`, `lnx01_history`, `proxmox_history-1/2`.

### 2.3.5 Opción mixta para las VMs Linux (decidida por Max, 17/11)

| Alternativa | Ventaja | Inconveniente | Decisión |
|---|---|---|---|
| Todo en Proxmox, en clase | Una sola copia de cada máquina | Gasta las sesiones en instalaciones | Descartada |
| **Mixta**: paquetes y configuración local en VirtualBox (casa); red, clúster, AG, `fence_pve`, Kea HA y dominio en Proxmox | Las sesiones se dedican a lo que solo se puede hacer allí | Una exportación e importación por máquina | **Elegida** |
| Todo en VirtualBox, incluido el clúster | Se ensaya todo en casa | Simular la red con las IPs reales, sin `fence_pve`, y repetir parte en Proxmox | Descartada |

Regla: **en cuanto una VM se importa, la de Proxmox es la buena**; la copia de VirtualBox no se vuelve a tocar.

### 2.4 Precauciones con los controladores de dominio

- **DC02 no se puede crear clonando DC01.** Un DC promovido no se clona nunca. DC02 se crea con una instalación limpia de Windows Server 2025 (o clonando una plantilla **sin dominio** a la que se haya pasado `sysprep /generalize /oobe /shutdown`), y después se promueve como DC adicional del dominio `cibernova.local`.
- Importar cada DC **una sola vez** y **dejar apagada para siempre (o borrar)** la copia de VirtualBox. Dos DC01 encendidos a la vez (misma IP y nombre) corrompen el dominio.
- No restaurar nunca un OVA o instantánea antigua de un DC después de que haya replicado con el otro (problema de *USN rollback*). Para recuperar un DC se usa la copia de *system state*.

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
- **Reenviadores** del servidor DNS: 192.168.200.254 (DNS del aula).
- Comprobar con `dcdiag /test:dns` y `nslookup cibernova.local`.
- **Estado (16/11, DC01 en VirtualBox en un equipo del aula):** reenviador configurado; `dcdiag /test:dns` supera todas las pruebas salvo *Reenviadores*: la VM de VirtualBox no tiene salida a Internet (solo red del aula), así que el reenviador no puede resolver nombres externos. Esperado; repetir en Proxmox, donde debe salir PASS.

### 3.3 Incidencias

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

- [x] Ejecutar el script 02 v2.2 en DC01 y hacer las capturas (16/11).
- [ ] Exportar DC01 a OVA, importarlo en Proxmox y comprobar red, DNS (`dcdiag /test:dns`) y rendimiento (pasa a la sesión 2, D-05).
- [ ] Crear DC02 (instalación limpia, no clon de DC01), promoverlo y comprobar la replicación (`repadmin /replsummary`).
- [x] LNX01 instalada en VirtualBox y exportada a OVA (17/11, apartado 2.3.1).
- [x] Importar LNX01 en Proxmox (VMID 128, 17/11). WEB01 y las demás VMs antiguas, borradas.
- [x] Netplan fijo de LNX01 con DNS públicos (17/11).
- [x] SQL Server 2025 instalado en LNX01 (sin configurar). LNX02 clonada y personalizada (17/11).
- [ ] Personalizar BKP01 (.30) y crear BKP02.
- [ ] `mssql-conf setup` en LNX01, LNX02 (Enterprise Developer) y BKP01 (Express); activar `hadr.hadrenabled`.
- [ ] **Todo subido a GitHub antes del 4/12/2026** (cierre del repositorio).
- [x] OU Equipos y Servidores: script 01 v2.1 ejecutado en DC01, 23 OU (16/11).
- [x] Ejecutar `03-cuentas-especiales.ps1` en DC01: 26 comprobaciones OK (16/11).
- [ ] Caducidad de `auditor.ext` cuando se sepa el fin de la Fase 3.
- [ ] GPO: denegar inicio de sesión interactivo a `G_Cuentas_Servicio`; privilegio de copia para `svc_backup`; perfil obligatorio de `recepcion.bcn`.
- [ ] Carpetas personales, cuotas y perfiles (cuando esté el servidor de ficheros).
