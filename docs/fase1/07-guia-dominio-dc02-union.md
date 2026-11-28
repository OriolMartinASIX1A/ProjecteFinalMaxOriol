# CiberNova – Dominio `cibernova.local`: cierre de DC01, montaje de DC02 y unión de todas las máquinas

_Grupo 3 · Max (Linux) y Oriol (Windows) · Versión 1.6 · 19/11/2026_

> Este documento se entiende solo: se puede pegar en otra IA o seguir en clase sin más explicaciones.
> Lista completa de tareas de la Fase 1: `docs/gestion/lista-tareas-fase1.md`.
> Lo que no está confirmado lleva **[PENDIENTE DE CONFIRMAR]**. Las contraseñas **nunca** se escriben aquí: los comandos las piden con `Get-Credential` o de forma interactiva.
> **Haced captura de cada paso marcado con 📸.** Nombre: `AAAA-MM-DD_sesionXX_maquina_descripcion.png`.

**Cambios de la v1.6 (19/11):** lecciones de la promoción real de DC02: credencial en formato UPN (`Administrador@cibernova.local`), quitar el reenviador a DC01 que pone el asistente (y no poner DC02 como reenviador en DC01) y estado: DC02 promovido y comprobado en VirtualBox; falta exportar e importar los dos DC.

**Cambios de la v1.5 (19/11):** procedimiento de DC02 reescrito según la decisión del 19/11, confirmada con Oriol: DC02 se instala y se promociona **en VirtualBox** junto a DC01 (adaptador puente), se comprueba la replicación y después se exportan e importan en Proxmox **los dos DC** (apartado 2). El apartado 1 queda solo con el estado y lo pendiente de DC01.

**Cambios de la v1.4 (19/11):** actualizado lo confirmado desde el 17/11: DNS de DC01 hecho por la interfaz gráfica (18/11), hora del PDC configurada, GPO de seguridad creadas con `05-gpo.ps1` v1.1, Internet en el rango .23–.33 confirmado, la red del aula intercepta el DNS, almacenamiento `local-lvm` y VMID 123/124 confirmados, nombres de servicio `www`/`sftp`/`sqlag` creados.

---

## 0. Contexto rápido

| Dato | Valor |
|---|---|
| Dominio | `cibernova.local` (NetBIOS `CIBERNOVA`), **un solo dominio** con dos DC |
| Red | 192.168.200.0/22 (máscara 255.255.252.0), puerta de enlace 192.168.200.254 |
| DNS de todas las máquinas | 192.168.202.23 y 192.168.202.24 (los DC); los DC reenvían a 8.8.8.8 y 1.1.1.1 (la red del aula intercepta el DNS) |
| Internet en el rango .23–.33 | Sí (confirmado el 17/11 con LNX01 y el 18/11 con DC01) |
| Hipervisor | Proxmox VE 9.2.21, nodo `PROC` (192.168.202.3), bridge `vmbr0` |
| Almacenamiento de discos | `local-lvm` (LVM-thin, 1,5 TB). VMID = 100 + último octeto de la IP (DC01 → 123, DC02 → 124) |
| Método de construcción | VirtualBox en casa → exportar OVA → importar en Proxmox en clase |

| IP | Máquina | SO | Papel en el dominio | OU de destino | Responsable |
|---|---|---|---|---|---|
| .23 | DC01 | Windows Server 2025 | 1.er controlador de dominio (hecho) | Domain Controllers | Oriol |
| .24 | DC02 | Windows Server 2025 | 2.º controlador de dominio | Domain Controllers | Oriol |
| .25 | FS01 | Windows Server 2025 | Miembro | Servidores | Oriol |
| .26 | FS02 | Windows Server 2025 | Miembro | Servidores | Oriol |
| .28 | LNX01 | Ubuntu 24.04 | Miembro (realmd + SSSD) | Servidores | Max |
| .29 | LNX02 | Ubuntu 24.04 | Miembro (realmd + SSSD) | Servidores | Max |
| .30 | BKP01 | Ubuntu 24.04 | Miembro (realmd + SSSD) | Servidores | Max |
| .31 | BKP02 | Ubuntu 24.04 | Miembro (realmd + SSSD) | Servidores | Max |
| .32 | CLI01 | Windows 11 | Miembro | Equipos\… [PENDIENTE DE CONFIRMAR sede] | Oriol |
| .33 | CLI02 | Windows 11 | Miembro | Equipos\… [PENDIENTE DE CONFIRMAR sede] | Oriol |
| — | PROC (host Proxmox) | Proxmox VE | **No se une** (propuesta) [PENDIENTE DE CONFIRMAR] | — | — |

**Por qué un solo dominio (resumen para la memoria):** el Anexo I pide una única plantilla, una única estructura de carpetas para las tres sedes y grupos de sede; la redundancia la dan los **dos DC del mismo dominio**, no dos dominios; las sedes se representan con OU (y, si hiciera falta, Sitios de AD); la frontera de seguridad real de AD es el bosque, así que un segundo dominio añade complejidad (confianzas, grupos duplicados, 4 DC) sin aislar de verdad.

**Orden obligatorio:** DC02 promocionado en VirtualBox junto a DC01 → DC01 y DC02 importados en Proxmox → FS01/FS02 → LNX01/LNX02/BKP01/BKP02 → CLI01/CLI02.
Sin los DC encendidos en Proxmox no se puede unir nada.

---

## 1. DC01: estado y lo que falta

### 1.1 Estado actual (19/11)
- Bosque `cibernova.local`, IP .23. **Sigue en VirtualBox** (desfase D-05). Se importará en Proxmox **junto con DC02**, después de promocionar DC02 en VirtualBox (apartado 2).
- 23 OU, 27 grupos, 89 empleados, 6 cuentas `adm.`, cuentas especiales (26 comprobaciones OK). FGPP `PSO_CiberNova_15` aplicada a `G_Politica_15`.
- **DNS completo y verificado el 18/11** (por la interfaz gráfica, paso a paso): zona inversa 192.168.202.0/24, registros fijos de los Linux, nombres de servicio `www`, `sftp` y `sqlag` → .27, envejecimiento 7+7, reenviadores **8.8.8.8 y 1.1.1.1**; la tarjeta usa solo 127.0.0.1. `nslookup` y `dcdiag /test:dns` correctos.
- **Por qué reenviadores:** DC01 sí tiene Internet, pero la red del aula **intercepta todo el tráfico DNS** (puerto 53): con solo servidores raíz da SERVFAIL. El DNS del aula (192.168.200.254) no responde desde el rango .23–.33.
- **Hora del PDC configurada** (18/11) con `hora.roa.es` y `es.pool.ntp.org`.
- **GPO de seguridad creadas el 18/11** con `05-gpo.ps1` v1.1 (`GPO_Dominio_CuentasServicio`, `GPO_Equipos_SinCuentasAdm`, `GPO_Dominio_Firewall`, `GPO_Servidores_Auditoria`); `94-comprobar-gpo.ps1`: 25 OK, 0 FALLO. Las de Equipos y Servidores se comprobarán al unir clientes y FS.

### 1.2 Configuración pendiente de DC01

| # | Tarea | Comando / dónde | Estado |
|---|---|---|---|
| 1 | **Configuración completa del DNS**: actualizaciones seguras, sin transferencias, zona inversa 192.168.202.0/24, reenviadores, registros fijos de los Linux, limpieza | Interfaz gráfica (18/11); scripts `04-configurar-dns.ps1` v1.2 y `93-comprobar-dns.ps1` v1.2 como referencia (memoria técnica 3.3) | **Hecho (18/11)** |
| 2 | **Fuente de hora** del PDC (DC01): todo el dominio sincroniza con él | `hora.roa.es` y `es.pool.ntp.org` (ver abajo) | **Hecho (18/11)** |
| 3 | **Registros DNS de los Linux** (no se registran solos) | Creados el 18/11 (también se pueden crear a mano, apartado 3.3) | **Hecho (18/11)** |
| 4 | **GPO** de seguridad: denegar inicio de sesión interactivo a `svc_*`, cuentas `adm.` sin inicio de sesión en equipos, Firewall de Windows, auditoría | `05-gpo.ps1` v1.1 y `94-comprobar-gpo.ps1` (memoria técnica 3.4) | **Hecho (18/11)**: 25 OK. Comprobar Equipos y Servidores al unir clientes y FS |
| 5 | Carpetas personales, cuotas, perfiles, grupos `DL_` y permisos NTFS | Necesitan **FS01** | Aplazado hasta tener FS01 |
| 6 | Evaluación de Windows: caduca ≈ 9/05/2027, queda 1 rearm | `slmgr /dlv`; antes de esa fecha `slmgr /rearm` | Alerta abierta |
| 7 | Papelera de reciclaje de AD | `Get-ADOptionalFeature -Filter 'Name -like "Recycle*"'` | [PENDIENTE DE CONFIRMAR si se activó] |
| 8 | OU vacía `Cuentasespeciales` (sin espacio) de la v1 | Ver abajo | Revisada el 18/11 |

Hora del PDC (configurada el 18/11; se deja como referencia):
```powershell
w32tm /config /manualpeerlist:"hora.roa.es,0x8 es.pool.ntp.org,0x8" /syncfromflags:manual /reliable:yes /update; Restart-Service w32time; w32tm /resync; w32tm /query /status
```
**Por qué importa:** Kerberos rechaza cualquier autenticación con más de **5 minutos** de diferencia. Si DC01 tiene mala hora, fallan la promoción de DC02 y las uniones al dominio.

Comprobación de la OU sobrante (PowerShell en DC01):
```powershell
Get-ADOrganizationalUnit -Filter 'Name -eq "Cuentasespeciales"' | Select-Object DistinguishedName
```
Si sale algo y está vacía:
```powershell
Get-ADOrganizationalUnit -Filter 'Name -eq "Cuentasespeciales"' | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -PassThru | Remove-ADOrganizationalUnit -Confirm:$false
```

---

## 2. DC02 en VirtualBox y paso de los dos DC a Proxmox (Oriol)

**Qué es DC02:** una **segunda copia del mismo dominio** `cibernova.local` (no un dominio nuevo). Replica usuarios, grupos, GPO y DNS. Si DC01 cae, DC02 sigue autenticando y resolviendo nombres → elimina el punto único de fallo de AD/DNS.

### 2.1 Decisión: promocionar DC02 en VirtualBox (Max, 19/11/2026; confirmado con Oriol)

- **Decisión:** DC02 se instala de cero en VirtualBox, **en el mismo equipo que DC01**, con las dos VMs en **adaptador puente**. Se promociona allí como segundo DC contra DC01, se comprueba la replicación y después se exportan **los dos DC** a OVA y se importan en Proxmox (VMID 123 y 124).
- **Por qué:** la promoción necesita que DC01 esté encendido y accesible. En VirtualBox ya lo está, así que no hay que esperar a importar DC01 (D-05) y no se gasta tiempo de sesión en Proxmox. Además, la replicación se comprueba antes de mover nada.
- **Alternativas descartadas:**
  - (a) Promocionar DC02 en Proxmox (lo que decía esta guía hasta la v1.4): obliga a importar antes DC01 y a hacer la promoción en horario de clase.
  - (b) Red interna de VirtualBox en lugar de adaptador puente: se propuso y Max la descartó el 19/11.
  - (c) Clonar DC01 para hacer DC02: prohibido (SID y USN duplicados).
- **Riesgos y cómo se evitan:**
  - **USN rollback:** a partir de la promoción, **no se puede volver a ninguna instantánea** de DC01 ni de DC02. Una instantánea antigua de un DC que ya ha replicado corrompe el dominio. Si hay instantáneas antiguas de DC01, no se restauran nunca.
  - **Dos copias vivas del mismo DC:** después de exportar, las copias de VirtualBox **no se vuelven a encender nunca** (se les quita el adaptador de red). Si se encendiera una a la vez que la de Proxmox, habría dos DC con el mismo nombre e IP y cambios divergentes.
  - **IP en Proxmox:** al importar, Windows ve una tarjeta de red nueva y pierde la IP fija; hay que volver a ponerla en los dos DC (apartado 2.7).

### 2.2 Instalación base de DC02 (VirtualBox, en el equipo de DC01) 📸
1. VM nueva en VirtualBox: Windows Server 2025 **con experiencia de escritorio** (igual que DC01) [PENDIENTE DE CONFIRMAR si preferís Core]. Recursos: los mismos que DC01 o los del documento de diseño (propuesta en revisión) [PENDIENTE DE CONFIRMAR]. Disco en el controlador **SATA** (el de serie en VirtualBox), BIOS igual que DC01 (si DC01 usa EFI, DC02 también).
2. **Instalación limpia** desde la ISO. **Nunca** clonar DC01 ni partir de su OVA. Si se partiera de una plantilla ya instalada, pasarla antes por `sysprep /generalize /oobe /shutdown`.
3. Red: *Configuración → Red → Adaptador 1 → Conectado a: **Adaptador puente***, con la **misma tarjeta física** que usa DC01. Comprobad que DC01 también está en *Adaptador puente* con esa tarjeta.
4. Nombre y zona horaria:
   ```powershell
   Set-TimeZone -Id "Romance Standard Time"; Rename-Computer -NewName DC02 -Restart
   ```
5. Comprobar la evaluación: `slmgr /dlv` 📸.
6. (Propuesta) Instalar los controladores VirtIO (`virtio-win-gt-x64.msi` de la ISO `virtio-win`) y el agente QEMU (`virtio-win-guest-tools.exe`) en **los dos DC** antes de exportar [PENDIENTE DE CONFIRMAR]. Windows instala los drivers aunque el hardware aún no exista; así en Proxmox se puede usar disco VirtIO SCSI y red VirtIO, mucho más rápidos que SATA/e1000 (causa probable de la lentitud del D-01). Si no se instalan, en Proxmox se usa disco **SATA** y red **E1000**.

### 2.3 Red y promoción (VirtualBox) 📸
**IP fija de DC02** apuntando a DC01 como DNS (para que encuentre el dominio):
```powershell
$if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.24 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23
```
> Con adaptador puente, las dos VMs están en la misma red física y se ven entre sí con las IP .23 y .24 aunque la red de casa sea otra (por ejemplo 192.168.1.0/24): la comunicación entre DC01 y DC02 no pasa por la puerta de enlace. Si la promoción se hace en casa, no habrá Internet en las VMs; no hace falta para promocionar. Si se hace en el aula, comprobad antes que nadie usa la .24: `ping 192.168.202.24` desde DC01 no debe responder.

Comprobar que DC02 ve el dominio y que la hora coincide con DC01 antes de seguir:
```powershell
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.cibernova.local; Test-NetConnection 192.168.202.23 -Port 389; w32tm /stripchart /computer:192.168.202.23 /samples:3 /dataonly
```
La diferencia de hora tiene que estar por debajo de 5 minutos (Kerberos).

Instalar el rol y promocionar (pide la credencial de un administrador del dominio y la **contraseña DSRM**, que no se apunta en ningún documento):
```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```
```powershell
Install-ADDSDomainController -DomainName cibernova.local -InstallDns -Credential (Get-Credential Administrador@cibernova.local) -SiteName "Default-First-Site-Name"
```
- **Credencial:** usar el formato **`Administrador@cibernova.local`**. El 19/11 el asistente rechazó `CIBERNOVA\Administrador` con «El nombre de usuario o la contraseña no son correctos».
- `-InstallDns`: DC02 también será servidor DNS (zona integrada en AD, se replica sola).
- Por defecto queda como **Catálogo Global**, necesario para iniciar sesión si cae DC01.
- Reinicia solo al terminar. 📸 pantalla de finalización.

### 2.4 Después de la promoción (VirtualBox)

**DNS cruzado** (buena práctica de Microsoft: primero el otro DC, después a sí mismo):
- En **DC02**:
  ```powershell
  $if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23,127.0.0.1
  ```
- En **DC01**:
  ```powershell
  $if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.24,127.0.0.1
  ```

**Reenviadores en DC02** (los reenviadores son de cada servidor, **no se replican**; los mismos que DC01):
```powershell
Set-DnsServerForwarder -IPAddress 8.8.8.8,1.1.1.1 -UseRootHint $true; Get-DnsServerForwarder
```
- **Ojo:** al promocionar, el asistente pone a **DC01 como reenviador de DC02** (copia el DNS de la tarjeta). Hay que **quitarlo** (el comando de arriba sustituye la lista; por la interfaz: `dnsmgmt.msc` → DC02 → Propiedades → Reenviadores). Tampoco se pone DC02 como reenviador en DC01. Motivo: *evita bucles y dependencia mutua* (las zonas ya están replicadas en los dos). Hecho el 19/11.
(Si estáis en casa sin Internet, `Resolve-DnsName www.google.com` fallará en las dos VMs: es normal y se comprueba otra vez en Proxmox.)

**Hora en DC02:** al ser un DC que no es PDC, sincroniza solo con la jerarquía del dominio (con DC01). Comprobación: `w32tm /query /source` debe mostrar DC01.

**Roles FSMO:** se quedan todos en DC01 (documentarlo). Si DC01 muriera para siempre, se transferirían a DC02 con `Move-ADDirectoryServerOperationMasterRole`.

### 2.5 Comprobaciones de la replicación (VirtualBox) 📸
```powershell
Get-ADDomainController -Filter * | Select-Object Name,IPv4Address,IsGlobalCatalog,Site
nltest /dclist:cibernova
repadmin /replsummary
repadmin /showrepl
dcdiag /q
Get-ADUser -Filter * | Measure-Object
Get-GPO -All | Select-Object DisplayName
```
- `repadmin /replsummary` debe mostrar **0 fallos** en las dos direcciones.
- El número de usuarios y las 4 GPO del 18/11 deben coincidir en los dos DC (las GPO llegan por SYSVOL/DFS-R).
- **Prueba de replicación:** crear un usuario de prueba en DC01, ejecutar `repadmin /syncall /AdeP` y comprobar en DC02 que aparece; borrarlo después.
- `dcdiag /q` solo muestra errores. Sin Internet (en casa), el único error aceptable es el de los reenviadores.
- `93-comprobar-dns.ps1 -Servidor 192.168.202.24` en DC02: zonas y registros iguales que en DC01.
- 📸 `..._dc02_get-addomaincontroller.png`, `..._dc02_replsummary.png`, `..._dc02_dcdiag.png`, `..._dc02_prueba-replicacion.png`

**No se exporta nada hasta que la replicación esté bien.** Si falla, se arregla en VirtualBox, donde todavía no hay riesgo de dos copias.

### 2.6 Preparar y exportar los dos DC (VirtualBox) 📸
1. **Apagar** primero DC02 y después DC01 con *Inicio → Apagar* (apagado completo: **no** "Guardar estado", **no** instantánea).
2. Mirar en cada VM *Configuración → Sistema → Placa base → Habilitar EFI* y apuntar si está marcado (hace falta para importar bien).
3. *Archivo → Exportar servicio virtualizado* → **una OVA por VM** (`DC01.ova` y `DC02.ova`) → formato **OVF 2.0** → política de MAC: **Quitar todas las direcciones MAC** → guardar en el disco del PC (no en el USB).
4. **Inmediatamente después:** en las dos VMs de VirtualBox, *Configuración → Red* → desmarcar **Habilitar adaptador de red**. A partir de aquí **no se vuelven a encender nunca**; las OVA quedan como copia fría.
5. 📸 exportación de cada VM y adaptador deshabilitado.

### 2.7 Importar los dos DC en Proxmox (en clase)
Almacenamiento `local-lvm` y VMID 123 (DC01) y 124 (DC02), confirmados el 17/11. Con LNX01, el asistente de importación de Proxmox falló (`OVF parser terminated unexpectedly … (500)`), así que se deja también el método manual.

1. Copiar las OVA al host (desde el PC, PowerShell):
   ```powershell
   scp .\DC01.ova .\DC02.ova root@192.168.202.3:/var/lib/vz/import/
   ```
   Comprobad antes el espacio libre de `local` (unos 24 GB): `pvesm status`. Si no caben las dos, se copian e importan de una en una.

2. **Opción A (interfaz web):** *PROC → local → Import* → `DC01.ova` → **Import** → VM ID `123`, `local-lvm`, `vmbr0`, tipo de SO *Microsoft Windows 11/2022/2025*, CPU tipo **host**, memoria fija (sin *Ballooning*). Disco **SATA** y red **E1000**, salvo que se hayan instalado los drivers VirtIO (2.2, paso 6). Si la VM tenía EFI: *BIOS → OVMF (UEFI)* y *Add → EFI Disk*.

   **Opción B (consola del host, si el asistente falla)**, un comando por línea:
   ```bash
   mkdir -p /var/lib/vz/import/dc01 && tar -xf /var/lib/vz/import/DC01.ova -C /var/lib/vz/import/dc01 && ls /var/lib/vz/import/dc01
   ```
   ```bash
   qm importovf 123 /var/lib/vz/import/dc01/DC01.ovf local-lvm
   ```
   Si `qm importovf` también falla, método manual como LNX01 (`qm create` + `qm importdisk` del `.vmdk` + `qm set --sata0`).

3. Ajustar el hardware y el arranque automático (DC01 primero):
   ```bash
   qm set 123 --name DC01 --ostype win11 --agent 1 --net0 e1000,bridge=vmbr0 --onboot 1 --startup order=1,up=60
   ```
   (Con drivers VirtIO: `--net0 virtio,bridge=vmbr0`.)

4. Repetir los pasos 2 y 3 con DC02 (`124`, carpeta `dc02`, `DC02.ova`) y `--startup order=2,up=60`, para que arranque después de DC01.

5. Borrar las OVA y sus carpetas de `local` después de importar:
   ```bash
   rm -rf /var/lib/vz/import/dc01 /var/lib/vz/import/dc02 /var/lib/vz/import/DC01.ova /var/lib/vz/import/DC02.ova && pvesm status
   ```

6. **Arrancar DC01** y volver a poner la IP fija (la tarjeta es nueva y no hereda la configuración):
   ```powershell
   $if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.23 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.24,127.0.0.1
   ```
   Si avisa de que la IP *ya está asignada a otro adaptador*, es la tarjeta antigua oculta de VirtualBox: Administrador de dispositivos → Ver → Mostrar dispositivos ocultos → desinstalar el adaptador gris (o `pnputil /remove-device`).
   Después: `ipconfig /registerdns; Restart-Service Netlogon`.

7. **Arrancar DC02** y hacer lo mismo con su IP:
   ```powershell
   $if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.24 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23,127.0.0.1
   ```
   Después: `ipconfig /registerdns; Restart-Service Netlogon`.

### 2.8 Comprobaciones de los dos DC en Proxmox 📸
En cada DC:
```powershell
Get-NetIPConfiguration
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.cibernova.local
Get-DnsServerForwarder
Resolve-DnsName www.google.com
w32tm /query /status
repadmin /replsummary
dcdiag /q
```
- `Get-DnsServerForwarder` → 8.8.8.8 y 1.1.1.1; `Resolve-DnsName www.google.com` resuelve (en el aula sí hay Internet).
- `repadmin /replsummary` → 0 fallos. Si hay errores justo después de arrancar, esperad unos minutos y forzad con `repadmin /syncall /AdeP`.
- Hora sincronizada (DC01 con `hora.roa.es`, DC02 con DC01).
- Desde LNX01: `ping -c 3 192.168.202.23` y `ping -c 3 192.168.202.24`.
- 📸 `2026-11-XX_sesionXX_dc01_importado-proxmox.png`, `..._dc02_importado-proxmox.png`, `..._dc01_ipconfig.png`, `..._dc02_ipconfig.png`, `..._dc01_replsummary-proxmox.png`, `..._dc01_dcdiag.png`

### 2.9 Prueba de caída de AD/DNS (obligatoria) 📸
Se hace cuando ya haya un cliente unido (apartado 3.4):
1. Apagar DC01 desde Proxmox.
2. En el cliente: `nltest /dsgetdc:cibernova /force` → debe responder **DC02**.
3. Iniciar sesión con un usuario del dominio y abrir `\\cibernova.local\...` (cuando exista DFS).
4. `Resolve-DnsName fs01.cibernova.local` → debe resolver (lo responde DC02).
5. Encender DC01 y comprobar `repadmin /replsummary`.
- 📸 cada paso: `..._cli01_dc01-apagado-login-ok.png`, etc.

---

## 3. Unir todas las máquinas a `cibernova.local`

### 3.1 Requisitos previos (todas las máquinas)

| Requisito | Por qué | Comprobación |
|---|---|---|
| DNS → .23 y .24 | El dominio se encuentra por DNS (registros SRV). Con el DNS del aula no se encuentra (además, no responde). | `Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.cibernova.local` / `host -t SRV _ldap._tcp.cibernova.local` |
| Hora igual que los DC (±5 min) | Kerberos rechaza la unión si la diferencia es mayor. | `w32tm /stripchart /computer:192.168.202.23 /samples:3` / `timedatectl` |
| Nombre definitivo antes de unir | Cambiarlo después obliga a renombrar la cuenta del equipo en AD o a volver a unir. | `hostname` |
| Windows: no ser un clon sin sysprep | SID duplicado. | `whoami /user` (comparar el prefijo) |
| Linux: `machine-id` único si es una copia | Varias herramientas (DHCP, SSSD, journald) lo usan como identificador. LNX02 ya tiene uno propio; **BKP01 todavía no** (clonada sin personalizar). | `cat /etc/machine-id` (distinto en cada VM) |
| Credencial de administrador del dominio | Para crear la cuenta del equipo. Se pide en pantalla, no se escribe. | — |

Comprobar la ruta exacta de las OU (en DC01) antes de usar los comandos:
```powershell
Get-ADOrganizationalUnit -Filter 'Name -eq "Servidores" -or Name -eq "Equipos"' | Select-Object DistinguishedName
```
En este documento se usa `OU=Servidores,OU=CiberNova,DC=cibernova,DC=local` y `OU=Equipos,OU=CiberNova,DC=cibernova,DC=local`. **Si la salida es distinta, cambiadla en los comandos.**

### 3.2 Servidores Windows miembros: FS01 y FS02 (Oriol)

Por cada uno (cambiando nombre e IP: FS01 → .25, FS02 → .26):
```powershell
Set-TimeZone -Id "Romance Standard Time"; Rename-Computer -NewName FS01 -Restart
```
```powershell
$if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.25 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23,192.168.202.24
```
```powershell
Add-Computer -DomainName cibernova.local -OUPath "OU=Servidores,OU=CiberNova,DC=cibernova,DC=local" -Credential (Get-Credential CIBERNOVA\Administrador) -Restart
```
Comprobación 📸 (`..._fs01_union-dominio.png`):
```powershell
Test-ComputerSecureChannel; (Get-CimInstance Win32_ComputerSystem).Domain; nltest /sc_query:cibernova; gpresult /r /scope computer
```
`Test-ComputerSecureChannel` debe devolver `True`. Al estar en el dominio, la hora se sincroniza sola con los DC. `gpresult` debe mostrar `GPO_Servidores_Auditoria` y `GPO_Dominio_Firewall` (comprobación pendiente de las GPO del 18/11).

### 3.3 Servidores Linux: LNX01, LNX02, BKP01 y BKP02 (Max)

**Método elegido:** `realmd` + `SSSD` + `adcli`.
**Por qué:** es el método recomendado por Ubuntu; SSSD guarda en caché las credenciales (se puede entrar aunque caigan los dos DC); más sencillo que Samba/winbind (alternativa descartada).

> **Internet:** confirmado el 17/11 desde el rango .23–.33 (`apt` funciona con DNS públicos). LNX01, LNX02 y BKP01 están ya en Proxmox (LNX02 y BKP01 son clones de LNX01, opción A), así que los paquetes del paso 4 se instalan directamente en Proxmox. La unión en sí (`realm join`) no necesita Internet, solo ver a los DC.

Valores por máquina:

| Máquina | Hostname | IP | VMID |
|---|---|---|---|
| LNX01 | `lnx01` | 192.168.202.28 | 128 |
| LNX02 | `lnx02` | 192.168.202.29 | 129 |
| BKP01 | `bkp01` | 192.168.202.30 | 130 |
| BKP02 | `bkp02` | 192.168.202.31 | 131 |

**Paso 1 – Hostname y `/etc/hosts`** (ejemplo LNX01):
```bash
sudo hostnamectl set-hostname lnx01 && echo "192.168.202.28 lnx01.cibernova.local lnx01" | sudo tee -a /etc/hosts && hostname -f
```

**Paso 2 – Red con DNS de los DC.** Hoy los Linux usan 8.8.8.8 y 1.1.1.1 (decisión del 17/11, mientras no estén los DC en Proxmox). Cuando DC01 y DC02 estén encendidos en Proxmox, se cambia el fichero netplan de cada VM (la tarjeta en Proxmox es `ens18`; comprobad con `ip -br link` y el nombre real del fichero con `ls /etc/netplan/`):
```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses: [192.168.202.28/22]
      routes:
        - to: default
          via: 192.168.200.254
      nameservers:
        addresses: [192.168.202.23, 192.168.202.24]
        search: [cibernova.local]
```
```bash
sudo chmod 600 /etc/netplan/50-cibernova.yaml && sudo netplan apply && resolvectl status ens18 && host -t SRV _ldap._tcp.cibernova.local
```
> `.local` es el dominio de mDNS: **no instaléis `avahi-daemon` ni `libnss-mdns`**, porque interceptarían las búsquedas de `cibernova.local`.

**Paso 3 – Hora con los DC:**
```bash
sudo sed -i 's/^#\?NTP=.*/NTP=192.168.202.23 192.168.202.24/' /etc/systemd/timesyncd.conf && sudo systemctl restart systemd-timesyncd && timedatectl timesync-status
```

**Paso 4 – Paquetes** (si pregunta el *realm* de Kerberos, escribid `CIBERNOVA.LOCAL` en mayúsculas):
```bash
sudo apt update && sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit krb5-user
```

**Paso 5 – Descubrir y unir** 📸:
```bash
sudo realm discover cibernova.local
sudo realm join -v --computer-ou="OU=Servidores,OU=CiberNova,DC=cibernova,DC=local" -U Administrador cibernova.local
```
`realm discover` debe mostrar `type: kerberos`, `server-software: active-directory` y `configured: no`; después de unir, `configured: kerberos-member`.

**Paso 6 – Carpeta personal automática y quién puede entrar:**
```bash
sudo pam-auth-update --enable mkhomedir
sudo realm deny --all && sudo realm permit -g G_Admin_Sistemas@cibernova.local
echo '%g_admin_sistemas@cibernova.local ALL=(ALL) ALL' | sudo tee /etc/sudoers.d/90-cibernova-admins && sudo chmod 440 /etc/sudoers.d/90-cibernova-admins && sudo visudo -cf /etc/sudoers.d/90-cibernova-admins
```
- **Mínimo privilegio:** solo `G_Admin_Sistemas` (las 6 cuentas `adm.`, confirmado el 18/11) puede iniciar sesión y usar `sudo`. El resto de los 89 empleados no puede entrar en los servidores.
- La cuenta local **`admincibernova` se mantiene** como acceso de emergencia (si caen los dos DC y la caché de SSSD ha caducado).
- Los servicios del clúster (Pacemaker, SQL Server, Kea, Bareos) **siguen con sus cuentas locales**: no dependen del dominio para arrancar.

**Paso 7 – Registro DNS en DC01** (los Linux no se registran solos). **Ya están creados desde el 18/11** (`lnx01`, `lnx02`, `bkp01`, `bkp02` y los nombres de servicio `www`, `sftp`, `sqlag` → .27). A mano sería así, uno por máquina:
```powershell
Add-DnsServerResourceRecordA -ZoneName cibernova.local -Name lnx01 -IPv4Address 192.168.202.28 -CreatePtr
```
Comprobación: `Get-DnsServerResourceRecord -ZoneName cibernova.local -RRType A | Where-Object HostName -match 'lnx|bkp|www|sftp|sqlag'`.

**Paso 8 – Comprobaciones** 📸 (`..._lnx01_realm-list.png`, `..._lnx01_login-dominio.png`):
```bash
realm list
id administrador@cibernova.local
getent group g_admin_sistemas@cibernova.local
sudo sssctl domain-status cibernova.local
```
Y desde otra máquina, iniciar sesión por SSH con una cuenta de `G_Admin_Sistemas` (debe entrar) y con un empleado normal (debe ser rechazado):
```bash
ssh adm.miguel.torres@cibernova.local@192.168.202.28
```
[PENDIENTE DE CONFIRMAR] qué cuenta `adm.` usaréis para la prueba.

**Si el inicio de sesión se rechaza aunque el usuario esté en el grupo:** en Ubuntu 24.04, SSSD aplica por defecto las GPO de inicio de sesión de Windows (`ad_gpo_access_control = enforcing`). Ojo: desde el 18/11 hay GPO de inicio de sesión (`GPO_Dominio_CuentasServicio`, `GPO_Equipos_SinCuentasAdm`). Revisad `sudo journalctl -u sssd -n 50` y, si la causa es la GPO, documentadlo antes de cambiar nada.

### 3.4 Clientes Windows 11: CLI01 y CLI02 (Oriol)

> **[PENDIENTE DE CONFIRMAR] nombres de los clientes.** El script 03 limitó `recepcion.bcn` al equipo **`BCN-RECEPCION`** (`LogonWorkstations`). Para poder demostrar esa restricción en las pruebas del Anexo I, **uno de los dos clientes debería llamarse `BCN-RECEPCION`** e ir a `Equipos\Recepcion`. Propuesta: CLI01 → `BCN-RECEPCION` (OU Recepcion) y CLI02 → `CLI02` (OU de una sede).

Por cada cliente (ejemplo CLI02, .33):
```powershell
Set-TimeZone -Id "Romance Standard Time"; Rename-Computer -NewName CLI02 -Restart
```
```powershell
$if=(Get-NetAdapter | Where-Object Status -eq 'Up').Name; New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.202.33 -PrefixLength 22 -DefaultGateway 192.168.200.254; Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.202.23,192.168.202.24
```
```powershell
Add-Computer -DomainName cibernova.local -OUPath "OU=Barcelona,OU=Equipos,OU=CiberNova,DC=cibernova,DC=local" -Credential (Get-Credential CIBERNOVA\Administrador) -Restart
```
(Cambiad `Barcelona` por la OU que se confirme; para el equipo de recepción, `OU=Recepcion`.)
- Windows 11 debe ser **Pro, Education o Enterprise**: la edición Home no puede unirse a un dominio. Comprobación: `(Get-CimInstance Win32_OperatingSystem).Caption`.
- **Los clientes se quedan con la IP fija de arriba** (cambio del 27/11): el DHCP (Kea) solo funciona en la red aislada `vmbr1`, para no repartir IP a los equipos del centro (diseño, apartado 3.4).

Comprobación 📸 (`..._cli02_union-dominio.png`, `..._cli02_login-usuario.png`):
```powershell
Test-ComputerSecureChannel; whoami; gpresult /r
```
`gpresult` debe mostrar `GPO_Equipos_SinCuentasAdm` y `GPO_Dominio_Firewall` (comprobación pendiente de las GPO del 18/11). Iniciar sesión con un empleado (p. ej. de Comercial) y comprobar que obliga a cambiar la contraseña en el primer inicio (requisito del Anexo I). Comprobar también que una cuenta `adm.` **no** puede iniciar sesión en el cliente.

### 3.5 Host Proxmox (PROC)
**Propuesta: no se une al dominio** [PENDIENTE DE CONFIRMAR].
**Por qué:** los DC son VMs de este host. Si PROC dependiera del dominio y los DC no arrancaran, no se podría entrar a Proxmox para arrancarlos (dependencia circular). Se accede con `root@pam` y un usuario propio para `fence_pve` con permisos mínimos.
**Alternativa:** añadir AD como *realm* de autenticación en Proxmox (*Datacenter → Permissions → Realms → Add → Active Directory*) manteniendo `root@pam` como acceso de emergencia. Aporta trazabilidad, pero añade dependencia.

---

## 4. Verificación final 📸

En DC01, todas las máquinas en su OU:
```powershell
Get-ADComputer -Filter * -Properties IPv4Address,OperatingSystem | Sort-Object DistinguishedName | Format-Table Name,IPv4Address,OperatingSystem,DistinguishedName -AutoSize
```
Resultado esperado: DC01 y DC02 en `Domain Controllers`; FS01, FS02, LNX01, LNX02, BKP01 y BKP02 en `Servidores`; los clientes en `Equipos\…`.

Resolución de nombres de todo el dominio (desde cualquier máquina Windows unida):
```powershell
"dc01","dc02","fs01","fs02","lnx01","lnx02","bkp01","bkp02","www","sftp","sqlag" | ForEach-Object { Resolve-DnsName "$PSItem.cibernova.local" -Type A | Select-Object Name,IPAddress }
```

📸 obligatorias:
- [ ] DC01 importado en Proxmox y `dcdiag`
- [ ] DC02: `Get-ADDomainController`, `repadmin /replsummary`, prueba de replicación
- [ ] Unión de cada máquina (`Test-ComputerSecureChannel` / `realm list`)
- [ ] `Get-ADComputer` con todas las máquinas en su OU
- [ ] Inicio de sesión de dominio en un Linux (permitido y denegado)
- [ ] Inicio de sesión de un empleado en un cliente
- [ ] GPO aplicadas en un servidor y en un cliente (`gpresult /r`)
- [ ] **Prueba de caída:** DC01 apagado y el cliente sigue autenticando con DC02

---

## 5. Qué apuntar en la bitácora

- Fecha, sesión y quién lo hizo.
- DC02: instalación limpia en VirtualBox, promoción, resultado de la replicación antes de exportar.
- Exportación de los dos DC (tamaño de cada OVA, EFI o BIOS) y adaptador de red deshabilitado en las copias de VirtualBox.
- Importación en Proxmox (VMID, almacenamiento, tipo de disco y red, asistente o método manual), IP vuelta a poner, `repadmin /replsummary` y `dcdiag`, si los reenviadores resuelven.
- Por cada máquina unida: nombre, IP, OU y comprobación OK.
- Decisión «un solo dominio con dos DC» y decisión «todas las máquinas al dominio» (17/11), con sus alternativas.
- Errores encontrados y cómo se resolvieron (tabla de errores de la memoria técnica).
- Desfases respecto al calendario (planificado, ocurrido, causa, medidas, impacto). **Recordad: el repositorio cierra el viernes 4/12.**

---

## 6. Pendiente de confirmar (resumen)

1. Si el host Proxmox (PROC) se une al dominio (propuesta: no).
2. OU de CLI01 y CLI02, y si uno se llama `BCN-RECEPCION`.
3. Si el rango .23–.33 puede tener DNS sin interceptar (entonces se quitarían los reenviadores). Preguntar al profesorado.
4. Instalar drivers VirtIO en los dos DC antes de exportar (propuesta).
5. Windows Server con escritorio o Core en DC02, y recursos de DC02.
6. Cuenta `adm.` para las pruebas de inicio de sesión en Linux.
7. Edición de Windows 11 de los clientes (no puede ser Home).
8. Si se activó la papelera de reciclaje de AD.

**Resuelto desde la v1.3:** procedimiento de DC02 (promoción en VirtualBox, confirmado con Oriol el 19/11); almacenamiento `local-lvm` y VMID 123/124 (17/11); Internet en el rango (17/11–18/11); servidor NTP del PDC (`hora.roa.es` + `es.pool.ntp.org`, 18/11); nombres de servicio `www`, `sftp`, `sqlag` (18/11); DNS y GPO de DC01 (18/11).
