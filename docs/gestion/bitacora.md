# Cuaderno de bitácora

Registro continuo de decisiones, problemas, soluciones y desfases. Una entrada por sesión (y fuera de horario cuando haya algo relevante). Las entradas más recientes van arriba.

---

## Plantilla de entrada

```markdown
### AAAA-MM-DD · Sesión N · Autor

**Hecho:**
- ...

**Problemas y soluciones:**
- Problema: ... → Solución: ...

**Decisiones:**
- ... (motivo: ...)

**Desfase:** No / Sí (ver D-XX)

**Siguiente sesión:**
- ...
```

## Plantilla de desfase

```markdown
### D-XX · Título corto

| Campo | Detalle |
|---|---|
| Planificado | Qué decía el calendario |
| Ocurrido | Qué pasó realmente |
| Causa | Por qué (retraso técnico, adelanto, imprevisto, replanificación) |
| Medidas | Qué se hizo para corregirlo o replanificar |
| Impacto | Efecto en el resto del proyecto |
```

---

## Desfases

### D-01 · Cambio de método de construcción: VirtualBox + OVA

| Campo | Detalle |
|---|---|
| Planificado | Crear todas las VMs directamente en Proxmox a partir de plantillas (sesión 1, 17/11). |
| Ocurrido | No se pudo instalar Windows Server en Proxmox. Tras reinstalar Proxmox con otra versión seguía yendo mal, y se pasó a crear las VMs en VirtualBox e importarlas como OVA. |
| Causa | Imprevisto técnico. **[PENDIENTE DE CONFIRMAR]**: error concreto al instalar Windows Server. |
| Medidas | Construcción en VirtualBox fuera de horario; importación en Proxmox con disco SATA y red E1000 (procedimiento en la memoria técnica, apartado 2.2). |
| Impacto | Positivo en tiempo: el trabajo de Windows avanza fuera del aula. Riesgos nuevos: problemas al importar y cuidado especial con los DC. La sesión 1 pasa a dedicarse a importar y comprobar. |

### D-02 · Adelanto de la parte de Windows

| Campo | Detalle |
|---|---|
| Planificado | DC01/DC02 en la sesión 2 (19/11); OU en la sesión 3 (24/11); script de altas en la sesión 4 (26/11). |
| Ocurrido | Antes de la sesión 1 ya están creados DC01 (bosque `cibernova.local`), las OU, los grupos globales, las políticas de contraseña y el script de altas de los 89 empleados y las 6 cuentas adm. |
| Causa | Adelanto gracias a trabajar en VirtualBox fuera de horario. |
| Medidas | Replanificación del calendario: las sesiones liberadas se usan para importar, DC02, servidor de ficheros y permisos, y para dar margen al AG de SQL Server. |
| Impacto | Unas 2 sesiones de margen en la parte de Windows. Actualización 16/11: los scripts 01 (v2.1), 02 (v2.2) y 03 se ejecutaron con éxito en DC01 tras corregir errores; DC02 todavía sin montar. |

### D-03 · LNX01: instalación limpia en lugar de adaptar WEB01

| Campo | Detalle |
|---|---|
| Planificado | Sesión 1 (17/11): adaptar la VM "WEB01" de Proxmox a LNX01 (cambiar nombre e IP a la .28). |
| Ocurrido | WEB01 no tiene Ubuntu 24.04, que es la versión que necesita SQL Server 2025. LNX01 se instaló de cero en VirtualBox el 17/11 por la mañana (fuera de horario) y se exportó a OVA. |
| Causa | Imprevisto técnico (versión de Ubuntu no válida en la VM heredada). |
| Medidas | Instalación limpia de Ubuntu Server 24.04.5 en VirtualBox y exportación a `LNX01.ova` (mismo método que Windows, D-01). En clase: importar, IP fija con netplan y apagar WEB01. Alternativas descartadas: `do-release-upgrade` sobre WEB01 (arrastra restos del proyecto anterior) y reinstalar en Proxmox (solo es posible en horario de clase). |
| Impacto | Ninguno en el calendario si LNX01 se importa en la sesión 1. LNX02, BKP01 y BKP02 quedan pendientes de comprobar la versión; si no son 24.04, se construyen igual. |

### D-04 · Cierre del repositorio de GitHub el 4/12/2026

| Campo | Detalle |
|---|---|
| Planificado | Trabajo hasta el 15/12, con las pruebas del Anexo I y las pruebas de caída en la sesión 7 (10/12) y la entrega en la sesión 8 (15/12). |
| Ocurrido | El 4/12/2026 es el último día para subir o modificar cosas en el repositorio. Todo lo que tenga que estar en la entrega (documentos, scripts, capturas, bitácora) debe estar subido ese día como muy tarde. |
| Causa | Fecha de cierre de la entrega (comunicada al equipo). |
| Medidas | Replanificación del calendario (17/11): todos los servicios, las 15 pruebas del Anexo I, las pruebas de caída y la de restauración pasan a las sesiones 2–6 (hasta el jueves 3/12). El viernes 4/12, fuera de horario: última revisión y subida. Las sesiones 7 y 8 quedan para ensayar la defensa (sin cambios en el repositorio). Opción mixta para Linux (paquetes instalados en casa) para ganar tiempo de laboratorio. Lista de tareas con todos los requisitos del enunciado y del Anexo I (`docs/gestion/lista-tareas-fase1.md`) para no dejarse nada. |
| Impacto | Alto: se pierden dos sesiones de margen para la entrega. Quedan 5 sesiones (10 h) para todos los servicios y las pruebas. **[PENDIENTE DE CONFIRMAR]** el nuevo calendario por Max y Oriol. |

### D-05 · DC01 no se importó en la sesión 1

| Campo | Detalle |
|---|---|
| Planificado | Sesión 1 (17/11): exportar DC01 a OVA, importarlo en Proxmox y comprobar red, DNS y dominio (punto de control del calendario). |
| Ocurrido | DC01 sigue en VirtualBox; no se exportó ni se importó. |
| Causa | **[PENDIENTE DE CONFIRMAR]** (Oriol). |
| Medidas | Plan B del calendario: DC01 sigue en VirtualBox. Se importa al empezar la sesión 2 (19/11). Si el asistente de importación de Proxmox falla como con LNX01, se usa el método manual (`tar` + `qm create` + `qm importdisk`, memoria técnica 2.3.2), con disco SATA y red E1000 hasta instalar los drivers VirtIO. | **Actualización 19/11 (decisión de Max, confirmada con Oriol):** DC01 ya no se importa solo: primero se promociona DC02 en VirtualBox junto a DC01 y después se exportan e importan los dos (guía 07 v1.5, apartado 2).
| Impacto | DC02 no se puede promover hasta que DC01 esté en Proxmox: la sesión 2 de Oriol empieza por DC01. Se recupera con el margen de Windows (D-02). **Actualización 19/11:** con la promoción en VirtualBox, DC02 ya no espera a que DC01 esté en Proxmox; lo que sigue esperando a los dos DC en Proxmox es la unión al dominio del resto de máquinas. |

---

## Entradas

### 2026-11-23 · Fuera de horario (clúster Pacemaker) · Max

Servidor encendido fuera de horario con permiso del profesor (confirmado por Max). Se adelanta todo lo previsto para Max en la sesión 3 (24/11).

**Hecho:**
- **`/etc/hosts` en LNX01, LNX02 y BKP01:** quitada la línea `127.0.1.1 <nombre>` y añadidas las IP reales de los cuatro Linux (.28–.31). `getent hosts` resuelve cada nombre a su IP y `ping` por nombre entre nodos funciona (0 % de pérdida, < 1 ms). Hora sincronizada en los tres (`timedatectl`: `Europe/Madrid`, `synchronized: yes`).
- **Paquetes** en los tres nodos: `pacemaker` (2.1.6), `pcs` y `fence-agents-pve` (en Ubuntu 24.04 `fence_pve` va en un paquete propio). `pcsd` activo. Contraseña de `hacluster` puesta en los tres (no se guarda en ningún documento).
- **Clúster de ejemplo `debian` borrado** en los tres (`pcs cluster destroy`): Ubuntu crea y arranca uno de un nodo al instalar `pacemaker`.
- **Clúster `cibernova-g3` de 3 nodos:** `pcs host auth lnx01 lnx02 bkp01 -u hacluster` → los tres `Authorized`; `pcs cluster setup cibernova-g3 lnx01 addr=192.168.202.28 lnx02 addr=192.168.202.29 bkp01 addr=192.168.202.30` (transporte knet, unicast y cifrado; claves `corosync authkey` y `pacemaker authkey` repartidas); `pcs cluster start --all && pcs cluster enable --all`.
- **Comprobación:** `pcs status` → 3 nodos `Online`, `partition with quorum`. `corosync-quorumtool -s` → `Expected votes: 3`, `Total votes: 3`, `Quorum: 2`, `Quorate: Yes`.
- **Usuario de Proxmox para el fencing** (shell de PROC): `fence@pve` con el rol propio `FenceCiberNova` (`VM.PowerMgmt` + `VM.Audit`) **solo** sobre `/vms/128`, `/vms/129` y `/vms/130` (`pveum user permissions fence@pve`).
- **Prueba manual:** `fence_pve ... --plug=129 --action=status --ssl-insecure` → `Status: ON` (comando con espacio delante para que la contraseña no quede en el historial).
- **Recurso STONITH:** `pcs stonith create fence-proxmox fence_pve ip=192.168.202.3 username=fence@pve password=… pve_node=PROC vmtype=qemu ssl_insecure=1 pcmk_host_map="lnx01:128;lnx02:129;bkp01:130"` → `Started bkp01`; desaparece el aviso `No stonith devices`.
- **Prueba real de fencing (prueba de caída):** `pcs stonith fence lnx02` → `Node: lnx02 fenced`; LNX02 `OFFLINE` y el clúster **sigue con quórum** con LNX01 y BKP01 (el coordinador pasa de lnx02 a bkp01). LNX02 vuelve sola en menos de 2 minutos; `pcs stonith history` → `reboot of lnx02 successful: delegate=bkp01, origin=lnx01`.
- 31 capturas (`2026-11-23_sesion03_*`, en `capturas-sesion03.zip`).

**Problemas y soluciones:**
- Problema: la línea `127.0.1.1 lnx01` en `/etc/hosts` (la pone Ubuntu al instalar). → Con ella, el nombre del nodo apunta a la interfaz de bucle local y Corosync puede escuchar en 127.0.1.1. Solución: borrarla y poner las IP reales.
- Problema: al instalar `pacemaker`, Ubuntu crea y arranca un clúster `debian` de un nodo en cada máquina. → Solución: `pcs cluster destroy` en los tres antes de crear `cibernova-g3`.
- Problema: `pveum user add` no pide contraseña y `fence@pve` no podía iniciar sesión. → Solución: `pveum passwd fence@pve`.
- Problema: `pcs stonith create` → `required stonith option 'vmtype' is missing`. → Solución: añadir `vmtype=qemu` (las máquinas son VM, no contenedores LXC). Se descartó `--force` (saltarse la comprobación).

**Decisiones:**
- **Clúster de 3 nodos (LNX01, LNX02, BKP01) sin qdevice** (Max). El diseño ponía en BKP01 a la vez la réplica de solo configuración del AG y el qdevice, y eso no encaja: según Microsoft, la réplica de solo configuración tiene que estar en un **nodo del clúster Pacemaker** (el agente del AG corre en los tres), y un qdevice tiene que estar **fuera** del clúster. Con BKP01 como nodo ya hay 3 votos. Alternativas: (a) 2 nodos + qdevice en BKP02 → descartada: BKP01 quedaría fuera del clúster y la réplica de solo configuración perdería sentido; fuera del esquema oficial; (b) **3 nodos** → elegida (esquema documentado por Microsoft). BKP01 nunca será primaria (Express, solo configuración); la VIP y Apache llevarán restricciones para no ir a BKP01.
- **`fence@pve` con mínimo privilegio** (Max): rol propio con solo `VM.PowerMgmt` y `VM.Audit` sobre las tres VMs del clúster. Alternativa descartada: `root@pam` (con su contraseña se podría borrar todo el servidor).
- **Un solo dispositivo STONITH** para los tres nodos (todos se apagan por el mismo Proxmox), con `pcmk_host_map` para traducir nombre de nodo → VMID.
- **Riesgos aceptados:** (1) la contraseña de `fence@pve` queda en la configuración de Pacemaker (CIB), legible por `root` y `hacluster` en los nodos; lo compensa el mínimo privilegio; (2) `ssl_insecure=1` porque el certificado de Proxmox es autofirmado (propuesta para la Fase 3: instalar la CA de Proxmox en los nodos y quitarlo).

**Desfase:** No (adelanto). Lo de la sesión 3 para Max está hecho el 23/11. La sesión 3 (24/11) puede empezar con el AG de SQL Server, previsto para la sesión 4.

**Siguiente:** AG de SQL Server: certificados y *endpoints* en los tres nodos, AG `CLUSTER_TYPE = EXTERNAL` (LNX01 primaria, LNX02 secundaria síncrona, BKP01 solo configuración), login de Pacemaker, recursos del AG y VIP .27 con restricciones (nunca en BKP01).


### 2026-11-19 · Sesión 2 (Linux: SQL Server y BKP02) · Max

**Hecho:**
- **`mssql-conf setup` en las tres máquinas con SQL Server**, ya con su nombre definitivo: **Enterprise Developer** (opción 2) en LNX01 y LNX02 y **Express** (opción 4) en BKP01. La contraseña de `sa` la escribió Max y no se guarda en ningún documento.
- **Always On activado** en las tres (`mssql-conf set hadr.hadrenabled 1`) y **Agente de SQL Server** en LNX01 y LNX02 (`sqlagent.enabled true`; Express no lo incluye). Reinicio de `mssql-server`.
- Comprobación en cada una con `sqlcmd ... -W -Q "SELECT @@SERVERNAME, SERVERPROPERTY('Edition'), SERVERPROPERTY('IsHadrEnabled')"`: `lnx01`/`lnx02` → Enterprise Developer Edition (64-bit), `alwayson = 1`; `bkp01` → Express Edition (64-bit), `alwayson = 1`. Cada servidor devuelve su propio nombre: configurar después de clonar fue correcto. Memoria en uso: unos 214 MB en LNX01/LNX02 y unos 128 MB en BKP01.
- **BKP02 creada (VMID 131, .31)** clonando la **instantánea `base-limpia`** de LNX01 (`qm clone 128 131 --name BKP02 --full 1 --snapname base-limpia`), es decir, Ubuntu actualizado **sin SQL Server**. Personalizada igual que los otros clones (hostname `bkp02`, `/etc/hosts`, `machine-id`, claves SSH, IP .31) con LNX01 apagada. Comprobado que no tiene paquetes ni servicio de SQL Server.
- **Las cuatro Linux actualizadas** (`apt full-upgrade` + reinicio) para tener el mismo kernel que BKP02 (6.8.0-151). Tras el reinicio, `mssql-server` arranca solo (`active`) en LNX01, LNX02 y BKP01.
- 16 capturas (`2026-11-19_sesion02_*`, en `capturas-sesion02.zip`) y apartado 13 de la memoria del proyecto (Google Doc), con la marca de dónde va cada captura. Apartado 7 de la memoria con todas las máquinas creadas.

**Problemas y soluciones:**
- Problema: `sqlcmd: command not found`. → Causa: el 17/11 se instalaron las herramientas pero no se añadió `/opt/mssql-tools18/bin` al PATH. Solución: `echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && source ~/.bashrc` en las tres.
- Problema: la salida de `sqlcmd` salía muy dispersa (columnas de cientos de caracteres). → Solución: opción `-W` (quita los espacios sobrantes).
- Problema: `apt full-upgrade` tardaba mucho en BKP02. → Se comprobaron los DNS del netplan (8.8.8.8 y 1.1.1.1, correctos). La espera venía de las actualizaciones acumuladas desde la instantánea del 17/11, incluido un kernel nuevo.

**Decisiones:**
- **BKP02 desde la instantánea `base-limpia`** (Max). Alternativas: (a) clonar LNX01 tal como está y desinstalar SQL Server (`apt purge`) → descartada: deja restos (`/var/opt/mssql`, repositorios, usuario `mssql`) y más pasos; (b) instalación limpia en VirtualBox → descartada por tiempo; (c) **clon de la instantánea anterior a SQL Server** → elegida: el servidor solo tiene lo que necesita (menos superficie de ataque) y sin pasos extra.
- **Mismo kernel en las cuatro Linux** (Max): los nodos de un clúster deben tener el mismo software para que se comporten igual en la conmutación.

**Desfase:** No. Lo previsto para Max en la sesión 2 (BKP01, `mssql-conf setup`, BKP02) está hecho. Queda para la sesión 3, como estaba planificado: Pacemaker + Corosync, qdevice y `fence_pve`. Sigue pendiente `serial-getty@ttyS0` en LNX01 (no imprescindible: se trabaja por SSH).

**Siguiente sesión (24/11):** clúster `cibernova-g3` (Pacemaker + Corosync) en LNX01 y LNX02, qdevice en BKP01, `fence_pve` contra la API de Proxmox (usuario propio con permisos mínimos). Preparar en casa los comandos y ficheros.

### 2026-11-18 · Fuera de horario (BKP01 personalizada) · Max

**Hecho:**
- **BKP01 (VMID 130) personalizada**, con LNX01 apagada para que no chocara la .28: hostname `bkp01`, `/etc/hosts`, `machine-id` y claves SSH regenerados, IP **192.168.202.30** en el netplan. Comprobado con `hostnamectl`, `cat /etc/machine-id`, `ip -br addr` (captura `2026-11-18_sesion01_bkp01_personalizado.png`).
- Memoria del proyecto (Google Doc): apartados 10 (LNX01 en VirtualBox), 11 (sesión 1) y 12 (SQL Server y clones) con las marcas de las capturas.

**Desfase:** No (adelanto de una tarea de la sesión 2).

### 2026-11-19 · Sesión 2 y tarde (DC02 en VirtualBox) · Max y Oriol

**Hecho (DC02, en VirtualBox, mismo equipo que DC01, adaptador puente):**
- Instalación limpia de Windows Server 2025, nombre DC02, IP 192.168.202.24/22, DNS 192.168.202.23. Hora con DC01: +0,16 s.
- Rol AD DS y promoción como segundo DC con **DNS y catálogo global**, replicando desde DC01.
- DNS cruzado en las tarjetas: DC01 → .24 + 127.0.0.1; DC02 → .23 + 127.0.0.1 (`ipconfig /all`).
- **Reenviadores** (por la interfaz gráfica: `dnsmgmt.msc` → servidor → Propiedades → Reenviadores): en DC02 se elimina DC01 y se añaden **8.8.8.8 y 1.1.1.1**; en DC01 se elimina DC02.
- Comprobaciones de replicación: `repadmin /replsummary` **0 errores** en las dos direcciones; `repadmin /showrepl` 5 particiones correctas; `net share` con SYSVOL y NETLOGON; SYSVOL en **estado 4**; sin errores nuevos en el registro del sistema; usuario `prueba.replicacion` creado en DC01 y visto en DC02.
- Comprobaciones finales en DC02 (18:03): `nslookup lnx01.cibernova.local 127.0.0.1` → .28 y la inversa de .28 → lnx01 (las zonas llegaron por replicación); `w32tm /query /source` → `DC01.cibernova.local`; `gpresult /r /scope computer` → `GPO_Dominio_CuentasServicio` y `GPO_Dominio_Firewall` aplicadas (las de Equipos y Servidores no aplican a Domain Controllers, es lo esperado); `netdom query fsmo` → los 5 roles en DC01. Todo funciona solo con los dos DC (todavía no hay más máquinas en el dominio).
- Capturas (decisión de Max): roles FSMO y licencia (`slmgr /dlv`) de DC02. Las GPO quedan cubiertas por el informe del script 94; la replicación, por las capturas de `replsummary`.

**Problemas y soluciones:**
- Problema: `nslookup` agotaba el tiempo en DC02. → Causa: DNS mal escrito en la tarjeta (**192.168.102.23**). Solución: corregido a 192.168.202.23.
- Problema: el asistente de promoción rechazaba `CIBERNOVA\Administrador` (*«El nombre de usuario o la contraseña no son correctos»*). → Solución: usar el formato UPN **`Administrador@cibernova.local`**.
- Problema: `dcdiag /q` con fallos en DFSREvent y SystemLog. → Causa: eventos de la propia promoción (16:27, error del KDC al arrancar). SYSVOL en estado 4 y sin errores nuevos: no hay avería; desaparecen a las 24 h.
- Problema: al promocionar, el asistente puso a **DC01 como reenviador de DC02** (usa el DNS que tenía la tarjeta), y en DC01 se había añadido DC02 como reenviador. → Solución: **se quitan los dos**; cada DC reenvía solo a 8.8.8.8 y 1.1.1.1 (más sugerencias de raíz).

**Decisiones:**
- **Los DC no se reenvían entre sí** (Max). Justificación: *evita bucles y dependencia mutua*. Los dos DC tienen las mismas zonas (replicadas por AD), así que reenviarse entre sí no resuelve nada nuevo, puede crear bucles cuando los públicos no responden y haría que cada DC dependiera del otro para salir a Internet (se pierde redundancia). Alternativa descartada: dejar el reenviador que pone el asistente.
- Firewall y VLAN (consulta de Max): **sin cambios** respecto al 16/11. Red plana; firewall en cada servidor (GPO en Windows ✅; ufw/nftables en Ubuntu ⏳ al montar cada Linux). Sigue pendiente preguntar al profesorado por las VLAN.

**Desfase:** No. DC02 queda promovido y comprobado en el día previsto (sesión 2); la importación en Proxmox de los dos DC pasa a la siguiente sesión (dentro del margen de D-05).

**Siguiente:** (propuesta, opcional) `virtio-win-guest-tools` en los dos DC; apagar DC02 y después DC01; exportar cada uno en su OVA (OVF 2.0, sin MAC); importarlos en Proxmox **de uno en uno** (en `local` solo hay ≈ 24 GB libres) como 123 y 124; arrancar primero DC01 y volver a poner IP y DNS (la tarjeta cambia); comprobar `repadmin /replsummary` y `nslookup` en los dos (📸). **No volver a encender las copias de VirtualBox.**

### 2026-11-19 · Antes y durante la sesión 2 (revisión de documentos) · Max

**Hecho:**
- **Revisión general de la documentación** frente a los criterios de evaluación del enunciado (estructura 20 %, rigor 25 %, justificación 20 %, diagramas 10 %, Git 15 %, bitácora 10 %). Hallazgos y propuestas en los puntos siguientes.
- **Corrección de los reenviadores en todos los documentos** (ya decidida el 18/11 a las 17:35, pero no había llegado al paquete V12): los reenviadores reales de DC01 son **8.8.8.8 y 1.1.1.1**, no 1.1.1.1 y 9.9.9.9. Corregido en diseño, memoria técnica, lista de tareas, calendario, guía 07, README y en esta bitácora (entrada del 18/11). Scripts `04-configurar-dns.ps1` y `93-comprobar-dns.ps1` → **v1.2** (solo cambian los reenviadores por defecto y la cabecera; en el 04, los nombres de servicio `www`, `sftp` y `sqlag` dejan de estar pendientes).
- Guía 07 → **v1.4**: actualizado lo confirmado desde el 17/11 (DNS, hora y GPO de DC01 hechos; Internet en el rango; DNS interceptado; `local-lvm` y VMID 123/124; nombres de servicio). Los apartados de importación de DC01 y promoción de DC02 **no se tocan** hasta que Oriol confirme (ver decisiones).
- El paquete `CiberNova_G3_V12.zip` se subió a Drive (Oriol, 19/11). La V10 sigue sin estar en Drive (está fusionada en la V12).

**Problemas y soluciones:**
- Problema: los 3 commits de Claude en GitHub (`a944e29`, `b8f2515`, `13d9b30`) tienen como autor `Claude <noreply@anthropic.com>` y las líneas `Co-Authored-By`/`Claude-Session`; se hicieron antes de la regla de autoría del 18/11. → Solución: **no se reescribe el historial** (obligaría a forzar el push en el repositorio de Oriol y podría romper su copia). Queda registrado aquí y todos los commits nuevos se firman como `paeplook` (Max) u `OriolMartinASIX1A` (Oriol), sin esas líneas.
- Problema: GitHub va por la V11 (17/11); la V12 y la V13 no están subidas, y el enunciado valora que la documentación sea "viva". → Propuesta: subir la V13 en cuanto Max dé permiso y, a partir de ahí, **un commit por sesión como mínimo** [PENDIENTE DE CONFIRMAR].
- Problema: las carpetas `scripts/linux/`, `configs/linux/`, `configs/windows/` y `docs/diagramas/` están vacías; el trabajo Linux solo está descrito en la memoria. → Propuesta: versionar los ficheros reales (netplan de cada VM, `sources.list.d` de Microsoft, script de personalización de clones) [PENDIENTE DE CONFIRMAR].
- Problema: no existen todavía tres entregables del enunciado: **diagramas**, **manual de operación y plan de recuperación** y **anexo de necesidades de IA** (DOC-01, DOC-04, DOC-06). → Propuesta: adelantar los diagramas y el anexo de IA a esta semana, porque no necesitan las máquinas [PENDIENTE DE CONFIRMAR].
- Problema: las sesiones 3–5 (6 h) concentran casi todo el trabajo Linux (Pacemaker, `fence_pve`, AG con réplica de configuración y VIP, Apache/PHP-FPM, SFTP, Kea HA y Bareos). → Propuesta: preparar en casa los ficheros de configuración y versionarlos en `configs/linux/`, y dejar escrito en el diseño el orden de recorte del plan B [PENDIENTE DE CONFIRMAR].

**Decisiones:**
- **DC02 se instala y se promociona en VirtualBox** (Max, 19/11), en el mismo equipo que DC01 y con adaptador puente; después se exportan los dos DC y se importan en Proxmox (VMID 123 y 124). Alternativa descartada: promocionar en Proxmox, porque obliga a importar antes DC01 (D-05) y gasta tiempo de sesión. Condiciones: DC02 nunca clonado de DC01; las copias de VirtualBox no se vuelven a encender tras exportar (*USN rollback*); en Proxmox hay que volver a poner las IP y arrancar primero DC01. **Confirmado con Oriol el 19/11** (Max): guía 07 → **v1.5** (apartado 2 reescrito: DC02 en VirtualBox, exportación e importación de los dos DC) y sesión 2 del calendario actualizada.
- Numeración de `docs/fase1/`: el 04 (manual de operación) y el 06 (anexo de IA) están reservados para esos entregables (README); no se renumera.

**Desfase:** No (la revisión no cambia el calendario; el riesgo de carga de las sesiones 3–5 queda anotado).

**Siguiente sesión:**
- Oriol: DC02 en VirtualBox según la guía 07 v1.5 (apartado 2) y, con la replicación bien, exportar e importar los dos DC.
- Max: lo previsto para la sesión 2 (personalizar BKP01, `mssql-conf setup`, Always On, BKP02).

### 2026-11-18 · Fuera de horario (DC01 en VirtualBox) · Max y Oriol

**Hecho:**
- DC01 **sí tiene salida a Internet** (`ping 8.8.8.8` correcto). Corrige lo anotado el 16/11 ("la VM no tiene salida a Internet"): lo que falla es el DNS, no la salida.
- Objetivo: que DC01 resuelva Internet por sí mismo con **127.0.0.1** como único DNS de la tarjeta y los **servidores raíz** (sin reenviadores). Configurado por la interfaz gráfica (pestañas Reenviadores, Sugerencias de raíz, Opciones avanzadas).
- Pestaña Supervisión: consulta simple **Correcto**, consulta recursiva **Error**. `Resolve-DnsName www.google.com -Server 127.0.0.1` → SERVFAIL.

**Diagnóstico (con capturas):**
- `(Get-DnsServerRootHint).Count` = 13: los servidores raíz están configurados.
- `Resolve-DnsName . -Type NS -Server 198.41.0.4` responde, pero con **TTL 33620** (un servidor raíz real responde siempre con 518400): contesta una caché intermedia.
- `Resolve-DnsName www.google.com -Server 198.41.0.4` devuelve **las IP de Google**. Un servidor raíz real nunca resuelve un nombre `.com` (solo da la referencia a los servidores de `.com`).
- **Conclusión: la red del aula intercepta todo el tráfico DNS (puerto 53)** y lo responde un resolutor propio, sea cual sea la IP de destino. Por eso funciona 8.8.8.8 en la tarjeta, no responde el .254 y falla la resolución desde la raíz (el interceptor no atiende las consultas iterativas que hace Windows).

- Prueba descartada: desactivar EDNS (`Set-DnsServerEDns -EnableProbes $false`) **no cambia nada** (sigue SERVFAIL); se vuelve a dejar como estaba.

**Decisión (Max, 18/11):** reenviadores **8.8.8.8 y 1.1.1.1** en el servidor DNS (**corrección de Max, 18/11, 17:35:** aquí se había anotado 1.1.1.1 y 9.9.9.9, pero los configurados de verdad son 8.8.8.8 y 1.1.1.1; dos proveedores distintos, Google y Cloudflare, para tener redundancia) de DC01 (configurados por la interfaz gráfica), nunca en la tarjeta, que se queda solo con 127.0.0.1. Se mantiene marcada "usar sugerencias de raíz si no hay reenviadores disponibles". Alternativas: resolución propia con los servidores raíz (preferida, imposible con la intercepción), DNS del aula (no responde), Google en la tarjeta (mala práctica en un DC). Pendiente preguntar al profesorado si el rango puede tener DNS sin interceptar. El script `84-deshacer-dns.ps1` **sí se ejecutó** después del script 04 (corrección del 18/11, 17:02: en un mensaje anterior se entendió lo contrario), así que el DNS se volvió a configurar desde cero **por la interfaz gráfica**: actualizaciones seguras, sin transferencias, zona inversa, registros de los Linux, nombres de servicio y envejecimiento. Scripts 04 y 93 pasan a la v1.1 (reenviadores nuevos; v1.2 el 19/11 con los reenviadores corregidos) y quedan como alternativa reproducible a la configuración gráfica.

**Hecho por la tarde (por la interfaz gráfica, confirmado por Max):**
- DNS completado y verificado: zona directa solo con actualizaciones seguras y sin transferencias, zona inversa 192.168.202.0/24, registros fijos `lnx01`, `lnx02`, `bkp01`, `bkp02` (con PTR), nombres de servicio `www`, `sftp` y `sqlag` → VIP 192.168.202.27 (sin PTR), envejecimiento y borrado 7 + 7 días, pestaña Supervisión y paso 8 (`nslookup` y `dcdiag /test:dns`) correctos.
- **DC02 no se crea a mano en el DNS:** al promocionarlo registra él mismo sus registros; uno creado a mano tendría otro propietario y la actualización segura lo rechazaría.
- Hora de DC01 con `hora.roa.es` y `es.pool.ntp.org` (`w32tm`).
- OU sobrante `Cuentasespeciales` revisada.
- Se aclara que los scripts 01–03 **no crean GPO** (quedaron aplazadas el 16/11). Se hacen **por script** para que queden versionadas: `05-gpo.ps1` v1.0 (4 GPO: `GPO_Dominio_CuentasServicio`, `GPO_Equipos_SinCuentasAdm`, `GPO_Dominio_Firewall`, `GPO_Servidores_Auditoria`) y `94-comprobar-gpo.ps1` v1.0 (comprobación e informes HTML). Probados con AD y GPO simulados (25 OK, segunda ejecución sin cambios). Confirmado que `G_Admin_Sistemas` solo tiene las 6 cuentas `adm.`. Las GPO no dependen de los Linux: se crean ya y las de Equipos y Servidores se aplicarán cuando entren las máquinas. Primera ejecución en DC01 (18/11, 17:18): creó las GPO de cuentas de servicio y de cuentas `adm.`, pero se paró en el firewall con *"No se encuentra ningún parámetro que coincida con el nombre del parámetro 'GPOSession'"*. **Causa:** `Get-NetFirewallRule` no admite `-GPOSession` (la simulación no lo detectó). **Solución:** `05-gpo.ps1` v1.1 busca la regla con `-PolicyStore`; se vuelve a ejecutar (es idempotente: lo ya creado no se repite). **Resultado:** segunda ejecución correcta; `gpupdate /force` y `94-comprobar-gpo.ps1` → **25 OK, 0 FALLO** (las 4 GPO creadas y vinculadas; DC01 aplica las de cuentas de servicio y firewall, con los 3 perfiles activados). Informes HTML en `C:\CiberNova\informes-gpo\`. Las GPO de Equipos y Servidores se comprobarán al unir CLI01/CLI02 y FS01/FS02.
- **Paquete V12:** fusión de V9 y V10 (preparadas en otra conversación sobre la V8) con la V11 de GitHub (`13d9b30`) más lo hecho el 18/11. Conflictos resueltos a mano en bitácora, calendario, diseño, guía del hipervisor, memoria técnica, inventario, VERSION y README; la lista de tareas se actualiza con lo confirmado en la sesión 1 (host, LNX01 importada, WEB01 borrada, clones, SQL Server instalado).

**Desfase:** No.

### 2026-11-17 (tarde) · Fuera de horario (preparación en otra conversación) · Max y Oriol

**Hecho / decidido:**
- **Todas las máquinas se unen al dominio `cibernova.local`** (decidido por Max): DC02 como segundo DC; FS01, FS02 y clientes con `Add-Computer`; Linux con realmd + SSSD. Alternativas y justificación en `claude/decisiones-fase1.md` y en la guía del dominio.
- **Un solo dominio** con dos DC (no dos dominios): el Anexo I pide una única plantilla y estructura de carpetas para las tres sedes; la redundancia la dan los dos DC; un segundo dominio añadiría confianzas, grupos duplicados y 4 DC sin aislar de verdad (la frontera de seguridad de AD es el bosque).
- **Configuración del DNS de DC01** preparada como script: `04-configurar-dns.ps1` v1.0 y `93-comprobar-dns.ps1` v1.0 (memoria técnica, apartado 3.3): zona solo con actualizaciones seguras y sin transferencias, zona inversa 192.168.202.0/24, reenviador, registros fijos de los Linux, nombres de servicio hacia la VIP (opcional) y limpieza de registros.

- **Error de planificación detectado (DNS):** se había dado DC01 por completo sin comprobar la configuración del DNS contra la lista de servicios del enunciado (el DNS es un servicio obligatorio). Causa: la zona y el reenviador que crea la promoción se tomaron como servicio terminado. Medida: script 04 y **lista de tareas** (`lista-tareas-fase1.md`) con todos los requisitos del enunciado y del Anexo I; solo se marca como hecho lo confirmado con comprobación o captura.
- **Revisión de todos los documentos del proyecto** (enunciado, Anexo I, presentación) y creación de la lista de tareas. Requisitos que no estaban recogidos como tarea: carpetas personales creadas por el script de alta, auditoría de acceso (P-11, P-39), vaciado de Intercambio (valorable), uso real de `svc_web`/`svc_bbdd`, cuentas `adm.` sin inicio de sesión en equipos de usuarios, copia de las VMs (norma 2), contenido web y datos SFTP iguales en los dos nodos, diagramas del diseño, anexo de necesidades de IA y manual de operación.
- **Cierre de GitHub el 4/12:** desfase D-04 y calendario replanificado.
- **Script 04 ejecutado en DC01** (confirmado por Max). Se decide **deshacer la configuración y empezar de cero** el DNS: nuevo script `84-deshacer-dns.ps1` v1.0 (quita solo lo añadido: zona inversa, registros fijos, limpieza y reenviadores; exporta antes las zonas y no toca las zonas ni los registros del dominio). Alternativas descartadas: borrar y recrear las zonas del dominio (hay que volver a registrar el DC) y desinstalar el rol DNS (con un solo DC el dominio deja de funcionar).

**Pendiente:** ejecutar el script 04 en DC01 y hacer capturas (`..._dc01_script04-dns.png`, `..._dc01_comprobar-dns.png`); confirmar nombres de servicio (`www`, `sftp`, `sqlag`); anotar qué se completó en la sesión 1.

**Desfase:** Sí, D-04 (cierre de GitHub).

### 2026-11-17 · Sesión 1 (15:00–17:00) y tarde con el servidor encendido (permiso del profesor) · Max

**Hecho:**
- **Comprobaciones del host** (capturas `proxmox_*`):
  - `lsblk`: un único disco `sda` de 1,6 TB → **RAID 10 por hardware confirmado**. LVM con `pve-root` (96 GB, ext4), `pve-swap` (8 GB) y **thin pool `pve-data` de 1,5 TB**.
  - `pvesm status`: `local` (directorio, 98 GB, 69 % usado, unos 24 GB libres) y `local-lvm` (**LVM-thin**, 1,5 TB, 6 % usado).
  - `ip -br link`: **solo `nic0` UP**; `nic1`–`nic3` DOWN (sin cable). Existe un `vmbr1` sin IP ni tarjeta física (origen **[PENDIENTE DE CONFIRMAR]**).
  - `ip -br addr`: `vmbr0` = **192.168.202.3/22** (máscara correcta).
  - `pveversion`: pve-manager 9.2.21, kernel 7.0.14-25-pve.
  - `pveperf /var/lib/vz`: **FSYNCS/SECOND 2235,82**, lecturas 395 MB/s, DNS EXT 396 ms. La caché de la controladora funciona.
- **VMs antiguas borradas** (100–107: WindSRV1, WindSRV2, UbuntSRV, USRVWEB01 = "WEB01", USRVWEB02, USRVDB01, USRVDB02, W2022P). Eran pruebas vacías, sin protección, plantillas ni instantáneas. Comando: `qm destroy <ID> --purge --destroy-unreferenced-disks 1`. Capturas de antes y después.
- **LNX01 importada en Proxmox (VMID 128)**: OVA subida por la web (*local → Import → Upload*, hash *None*, 1,81 GiB). El asistente de importación falló y se importó a mano. Configuración: 2 núcleos `host`, 4 GB, `scsi0` 60 GB en `local-lvm` (VirtIO SCSI single, iothread), red VirtIO en `vmbr0`, agente QEMU activado.
- La tarjeta pasó a llamarse `ens18` y estaba DOWN (el netplan tenía `enp0s3`). Prueba con IP temporal (`sudo ip addr add 192.168.202.28/22 dev ens18` + ruta por defecto): **ping a la puerta de enlace OK e Internet OK** desde la .28.
- Netplan definitivo por SSH, en curso después de la sesión (con permiso del profesor): **[PENDIENTE DE CONFIRMAR]** el resultado.

**Problemas y soluciones:**
- Problema: el asistente de importación dio `OVF parser terminated unexpectedly trying to parse /var/lib/vz/import/LNX01.ova (500)`. Con `tar -tvf` se vio que la OVA estaba bien (`.ovf`, `.mf`, `.vmdk`). → Solución: importación manual: `tar -xvf`, `qm create 128 ...`, `qm importdisk 128 lnx01/LNX01-disk001.vmdk local-lvm`, `qm set 128 --scsi0 local-lvm:vm-128-disk-0,iothread=1 --boot order=scsi0`.
- Problema: `qm create` dio `400 too many arguments`: la `\` de continuación de línea quedó en medio al pegar. → Solución: el comando en una sola línea.
- Problema: en la consola noVNC no se puede pegar (es una pantalla y un teclado virtuales, sin portapapeles). → Solución: dar IP y trabajar por SSH. Propuesta: consola serie xterm.js (`qm set 128 --serial0 socket` + `serial-getty@ttyS0`).
- Problema: `ip link set` → "no permitido". → Solución: faltaba `sudo`.
- Hallazgo: las VMs Ubuntu antiguas se habían instalado con la ISO `ubuntu-26.04.1` (por eso WEB01 no era 24.04), y **los Windows Server tenían el disco en IDE** (`ide0`). Con el FSYNCS del host, el disco IDE emulado es la causa más probable de la lentitud de Windows (D-01).
- No se pudo usar el navegador integrado de Claude: el certificado de Proxmox es autofirmado. Propuesta: instalar `/etc/pve/pve-root-ca.pem` como CA de confianza en el portátil.

**Decisiones:**
- Borrar las 8 VMs antiguas (Max).
- VMID = 100 + último octeto de la IP (LNX01 → 128).
- **Opción A para crear LNX02 y BKP01: clonar LNX01 en Proxmox** y personalizar cada clon (Max). Alternativa descartada: instalarlas en VirtualBox (una tarde por máquina). Los Linux sí se pueden clonar (no son DC) si cada clon tiene `machine-id`, claves SSH, hostname e IP propios.
- **Opción mixta para las VMs Linux** (Max): en casa, en VirtualBox, se instala todo lo que no depende de la red (paquetes de SQL Server, Apache/PHP, ODBC, Pacemaker, Kea, Bareos, configuración local). En Proxmox: netplan, clúster, AG, `fence_pve`, Kea HA y unión al dominio. Una vez importada, la copia de Proxmox es la buena y la de VirtualBox no se toca.
- **LNX02, BKP01 y BKP02 no existen** (las VMs antiguas eran otras y se han borrado): se crean como LNX01.

**Desfase:** Sí: D-05 (DC01 no importado) y D-04 (cierre del repositorio el 4/12, replanificación).

**Preguntas al profesorado:** no dio tiempo (DHCP propio, VLAN, fecha de la defensa). La salida a Internet del rango .23–.33 queda **confirmada** con LNX01.

**Siguiente sesión (jue 19/11):** ver calendario replanificado.

**Después de la sesión (17:30–18:45, servidor encendido con permiso del profesor):**
- **Netplan fijo en LNX01** por SSH (`ens18`, 192.168.202.28/22, puerta 192.168.200.254). Aguanta el reinicio (`ip -br addr`, SSH y *Summary* de Proxmox con la IP del agente QEMU).
- **Problema: DNS del aula.** `curl` a `packages.microsoft.com` → `Could not resolve host`. `ping 8.8.8.8` funciona, pero `resolvectl query` se queda colgado con 192.168.200.254. **El router del aula da salida a Internet pero no responde a consultas DNS desde este rango** (esto explica también el FAIL del reenviador en el `dcdiag` de DC01). → Solución: DNS públicos en netplan (`addresses: [8.8.8.8, 1.1.1.1]`), probados antes con `sudo resolvectl dns ens18 8.8.8.8 1.1.1.1`. Cuando estén DC01/DC02, los Linux usarán .23/.24 y los DC reenviarán a 8.8.8.8/1.1.1.1 **[PENDIENTE DE CONFIRMAR]**.
- Puerto serie añadido a LNX01 (`qm set 128 --serial0 socket`) para la consola xterm.js (falta activar `serial-getty@ttyS0` dentro).
- Instantánea `base-limpia` de LNX01 (`qm snapshot 128 base-limpia`).
- **SQL Server 2025 instalado en LNX01, sin configurar**: clave y repositorios de Microsoft (`mssql-server-2025.list` y `prod.list` de Ubuntu 24.04), `mssql-server` y `mssql-server-ha` 17.0.5065.9-3, `mssql-tools18` y `msodbcsql18` 18.7.1.1-1, `unixodbc-dev`. **No se ejecutó `mssql-conf setup`**, para poder clonar sin que SQL Server guarde el nombre del equipo.
- **Opción A: clones en Proxmox** (decidido por Max): `qm clone 128 129 --name LNX02 --full 1` y `qm clone 128 130 --name BKP01 --full 1` (con LNX01 encendida).
- **LNX02 personalizada** (con LNX01 apagada, por SSH a la .28): hostname `lnx02`, `/etc/hosts`, `machine-id` nuevo (`95ec319c…`), claves SSH de host nuevas (`dpkg-reconfigure openssh-server`), IP **.29/22** en netplan. Comprobado tras reiniciar.
- **BKP01 (130) clonada pero sin personalizar**: dentro tiene todavía hostname `lnx01` e IP .28. **No arrancarla con LNX01 encendida.**
- Borradas del host las ISO `ubuntu-26.04.1-live-server-amd64.iso` y `WinServ_2022.iso` (se usa Windows Server 2025).
- Capturas: 30 renombradas con el formato del proyecto (incluidas las recuperadas de la conversación y los historiales `history` de PROC y LNX01 como evidencia de los pasos sin captura).

**Problemas y soluciones (tarde):**
- Problema: no se hicieron capturas de muchos pasos. → Solución: recuperar las salidas pegadas durante la sesión, rehacer las del estado actual y usar `history` y el *Task History* de Proxmox como evidencia de lo que no se puede repetir.
- Problema: los clones completos ocupan el disco entero en el thin pool (`Data% 100` en `lvs`). → Propuesta: `discard=on` en los discos y `sudo fstrim -av` dentro de cada VM para devolver el espacio libre **[PENDIENTE DE CONFIRMAR]**.
- Hallazgo en el `history` de PROC: el equipo ya había importado a mano una OVA de Windows Server 2022 (`tar` + `qemu-img convert` + `qm importdisk`) antes de la VM 107.

**Siguiente (sesión 2, jue 19/11) para Max:** personalizar BKP01 (.30), `mssql-conf setup` (Enterprise Developer en LNX01/LNX02, Express en BKP01), activar Always On (`hadr.hadrenabled`), crear BKP02 y empezar Pacemaker.


### 2026-11-17 (mañana) · Fuera de horario · Max

**Hecho:**
- Comprobado que la VM "WEB01" de Proxmox no es Ubuntu 24.04: se descarta (D-03).
- LNX01 instalada de cero en VirtualBox: ISO `ubuntu-24.04.5-live-server-amd64.iso`, 2 vCPU, 4 GB de RAM, disco dinámico de 60 GB, BIOS (sin EFI), red NAT. Hostname `lnx01`, usuario `admincibernova`, OpenSSH.
- `lsb_release -a` → Ubuntu 24.04.5 LTS (noble).
- Disco: el instalador solo asignó 29 de 58 GB al volumen raíz. Ampliado con `sudo lvextend -r -l 100%VG /dev/ubuntu-vg/ubuntu-lv` → `/` de 57 GB.
- `apt update` + `apt full-upgrade -y`, `qemu-guest-agent` instalado, zona horaria `Europe/Madrid` (reloj sincronizado).
- Red de cloud-init desactivada en `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` (`network:` / `  config: disabled`).
- Comprobación tras reiniciar: `hostnamectl`, `timedatectl`, `ip -br link` (tarjeta `enp0s3`, IP NAT 10.0.2.15).
- Exportada a OVA (OVF 2.0, sin direcciones MAC) en `C:\Users\masen\Documents\LNX01.ova`.
- 8 capturas en `E:\LNX01` (`2026-11-17_sesion01_lnx01_*.png`). Memoria del proyecto: nuevo apartado 10 (LNX01).

**Problemas y soluciones:**
- Problema: el instalador de Ubuntu deja la mitad del grupo de volúmenes sin usar. → Solución: `lvextend -r -l 100%VG` (amplía también el ext4 en caliente).
- Problema: la primera exportación al USB (`E:`) iba muy lenta (leía la VM y escribía la OVA en el mismo USB) y se canceló sin querer. → Solución: exportar a `C:` y copiar después la OVA al USB. Borrar el `E:\LNX01.ova` incompleto si quedó.
- Problema: un fichero creado con `sudo nano` se guardó en la carpeta personal por no haber hecho `cd` antes. → Solución: `sudo mv` a `/etc/cloud/cloud.cfg.d/`. Lección: usar siempre la ruta completa al editar ficheros del sistema.

**Decisiones:**
- LNX01 se instala de cero en VirtualBox (D-03).
- Contraseñas sencillas durante el montaje (riesgo aceptado); se cambian todas al empezar la Fase 3 y se guardan en un gestor (KeePassXC o Proton Pass, pendiente). Propuesta: inventario de dónde se usa cada credencial (sin la contraseña).
- No actualizar a Ubuntu 26.04 aunque el sistema lo ofrezca: SQL Server 2025 necesita 24.04.

**Desfase:** Sí (ver D-03).

**Siguiente sesión (17/11, 15:00):**
- Copiar `LNX01.ova` al USB, importarla en Proxmox (disco VirtIO SCSI, red VirtIO, QEMU Guest Agent activado, disco de datos), apagar WEB01, configurar netplan con 192.168.202.28/22 y comprobar red. Capturas.
- Comprobar la versión de Ubuntu de LNX02, BKP01 y BKP02.

### 2026-11-16 (noche, 10) · Max y Oriol

**Hecho:**
- `01-crear-ou-grupos.ps1` v2.1 ejecutado en DC01: `90-comprobar-ou-grupos.ps1` muestra **23 OU** (con Equipos y Servidores) y **27 grupos**.
- Memoria revisada: capturas completas de DC01 y texto de las OU nuevas corregido.
- Revisión de los documentos del repositorio: actualizadas las tareas ya hechas.
- Memoria: eliminadas las contraseñas del apartado 7 (no se guardan contraseñas en documentos, Drive ni Git). Exportada a PDF y subida al repositorio como `docs/Proyecto-memoria.pdf`, sustituyendo al `Proyecto.pdf` antiguo.
- **DC01 queda completo para la Fase 1.** Solo falta exportarlo a OVA e importarlo en Proxmox (sesión 1, 17/11), y repetir allí `dcdiag /test:dns`.

**Desfase:** No.

### 2026-11-16 (noche, 9) · Max y Oriol

**Hecho:**
- Memoria (Google Docs): añadidas las capturas que faltaban (`Get-ADDomain`/`Get-ADForest`, políticas de contraseña, reenviador y `dcdiag`, `ipconfig` y ping) y aclarado el apartado 6.
- Script `01-crear-ou-grupos.ps1` **v2.1**: nuevas OU **Equipos** (Barcelona, Madrid, Valencia, Recepcion) y **Servidores**. Probado con Active Directory simulado partiendo de las 17 OU actuales: crea solo las 6 nuevas (total 23) y no toca nada más; una segunda ejecución no crea nada.

**Decisiones:**
- **Se crean las OU Equipos y Servidores** (motivo: el contenedor por defecto `Computers` no admite GPO, y hacen falta GPO de equipo para BCN-RECEPCION, perfiles y unidades de red). Los DC se quedan en `Domain Controllers`.

**Aclaración (primer intento en Proxmox):** DC01 llegó a promoverse y DC01 y DC02 se veían por ping, pero DC02 no se pudo unir al dominio por la lentitud; el dominio dejó de responder y no se podía iniciar sesión. Se eliminaron las máquinas, se probó con éxito exportar una OVA desde VirtualBox y se empezó de nuevo en VirtualBox (desfase D-01).

**Problemas:**
- No se ha podido exportar DC01 a OVA hoy: el profesorado ha apagado el servidor hasta mañana. Se hará al empezar la sesión 1 (17/11).

**Desfase:** No (la exportación pasa al inicio de la sesión 1, que ya incluía la importación de DC01).

**Siguiente sesión (17/11):**
- Ejecutar `01-crear-ou-grupos.ps1` v2.1 en DC01 (si no se ha hecho) y captura con `90-comprobar-ou-grupos.ps1` (23 OU).
- Exportar DC01 a OVA e importarlo en Proxmox.

### 2026-11-16 (tarde-noche, 8) · En el aula · Oriol

**Hecho:**
- Script 03 ejecutado en DC01: las 6 cuentas especiales creadas; `92-comprobar-cuentas-especiales.ps1` → **26 comprobaciones OK**.
- Capturas en la memoria: estructura de OU (17), grupos (24 antes del script 03) y Admins. del dominio, empleados por departamento (89), becarios, cuentas adm., horario de izan.moreno (L-V 8:00-15:00, correcto) y `slmgr /dlv`.
- **Caducidad de la evaluación de Windows Server 2025 (DC01):** 174 días → **≈ 9/05/2027**, con **1 rearm** disponible. Riesgo para la Fase 3: ejecutar `slmgr /rearm` antes de esa fecha (+180 días).

**Desfase:** No.

### 2026-11-16 (tarde-noche, 7) · Max y Oriol

**Decisiones:**
- Se planteó no crear las cuentas especiales en la Fase 1 ("no se usan hasta más adelante"). **Se descarta** porque el Anexo I las sitúa en la Fase 1: `recepcion.bcn` se usa en la prueba 10 de la demo de la Fase 1; `svc_backup`, `svc_web` y `svc_bbdd` corresponden a servicios obligatorios de la Fase 1; `auditor.ext` "se crea deshabilitada" y `svc_ia` está "reservada" para la Fase 2. Se crean ahora (script 03) y se deja para su fase solo la **configuración** que depende de servicios que aún no existen (GPO, perfil obligatorio, permisos de carpeta, permisos de `svc_ia` sobre los logs, caducidad de `auditor.ext`).
- Nuevo script de comprobación `92-comprobar-cuentas-especiales.ps1`: revisa los requisitos del Anexo I, apartado 5, y marca OK / FALLO (26 comprobaciones) para la captura.

**Desfase:** No.

### 2026-11-16 (tarde-noche, 6) · En el aula (DC01 en VirtualBox) · Oriol

**Hecho:**
- DNS de DC01: reenviador 192.168.200.254 añadido (`Add-DnsServerForwarder`); la tarjeta de DC01 usa 127.0.0.1 como DNS (correcto mientras no exista DC02).
- `dcdiag /test:dns`: Connectivity, Autenticación, Básica, Delegación, Dinámica y Registros superadas. **Reenviadores: FAIL** ("no hay ningún reenviador válido").

**Problemas y soluciones:**
- **Fallo de reenviadores: causa en diagnóstico.** DC01 se está ejecutando en VirtualBox en un ordenador **del aula**, así que debería llegar a 192.168.200.254. (Primero se atribuyó por error a estar trabajando desde casa; corregido.) **Causa confirmada por Oriol:** la VM de VirtualBox no tiene salida a Internet; solo tiene red dentro del aula. Sin salida, el reenviador no puede resolver nombres externos, así que el FAIL es **esperado** y no afecta al dominio (el DNS de `cibernova.local` supera el resto de pruebas). **Repetir `dcdiag /test:dns` tras importar DC01 en Proxmox**, donde sí hay salida por 192.168.200.254 (el host se actualizó por esa vía). **[PENDIENTE DE CONFIRMAR]:** modo de red del adaptador de VirtualBox, para documentarlo.
- **Diagnóstico (16/11):** `ipconfig /all` correcto (IP 192.168.202.23, máscara 255.255.252.0, puerta de enlace 192.168.200.254, DNS 127.0.0.1); `ping 192.168.200.254` correcto (0 % de pérdidas, TTL 64: DC01 está en la misma red física del aula, adaptador de VirtualBox Intel PRO/1000 MT); `Test-NetConnection 192.168.200.254 -Port 53` → `TcpTestSucceeded: False`. `Resolve-DnsName www.google.com -Server 192.168.200.254 -DnsOnly` (UDP) → *tiempo de espera agotado*. **Conclusión confirmada:** DC01 tiene red con el router del aula, pero el router **no le da servicio DNS** (ni por TCP ni por UDP) ni salida a Internet. El reenviador de DC01 está bien configurado; el FAIL de `dcdiag` se debe a la red, no a DC01.
- **Pendiente:** (1) preguntar al profesorado si el rango 192.168.202.23–.33 tiene salida a Internet y qué DNS hay que usar; (2) repetir la prueba desde la shell de Proxmox (`nslookup www.google.com 192.168.200.254`) para comparar; (3) repetir `dcdiag /test:dns` con DC01 ya en Proxmox. Si el rango no tiene salida, afecta a la instalación de paquetes en los Ubuntu (ver calendario, sesión 1).

**Desfase:** No.

### 2026-11-16 (noche, 5) · Fuera de horario · Oriol

**Problemas y soluciones:**
- **Problema:** al pegar en PowerShell un comando de comprobación copiado del chat, daba *"Debe proporcionar una expresión de valor después del operador '+'"* y *"Token '$.Name' inesperado"*.
- **Causa:** al copiar, se perdieron los guiones bajos de la variable automática `$_` (quedó `$.Name` en lugar de `$_.Name`); algunos visores interpretan los `_` como formato de texto. Además, los comandos de varias líneas no se pegaban bien en la consola.
- **Solución:** los comandos de comprobación pasan a ser scripts del repositorio (`90-comprobar-ou-grupos.ps1` y `91-comprobar-usuarios.ps1`), que solo leen y no cambian nada, y usan `$PSItem` (equivalente a `$_` pero sin guion bajo).
- **Lección aprendida:** los comandos largos se entregan como fichero `.ps1`, no para copiar y pegar.

**Desfase:** No.

### 2026-11-16 (noche, 4) · Fuera de horario · Max y Oriol

**Hecho:**
- Script `03-cuentas-especiales.ps1` v1.0: crea recepcion.bcn, auditor.ext, svc_backup, svc_web, svc_bbdd y svc_ia con sus restricciones del Anexo I, y los grupos G_Recepcion, G_Auditor_Externo y G_Cuentas_Servicio. Probado con Active Directory simulado. Pendiente de ejecutar en DC01.

**Decisiones:**
- Cuentas de servicio **normales** (contraseña de 32 caracteres, rotación manual documentada) en lugar de **gMSA** (motivo: las gMSA solo funcionan en servidores Windows y tres de las cuentas se usarán en Ubuntu).
- Equipo de recepción: **BCN-RECEPCION**.
- `auditor.ext` **sin fecha de caducidad** por ahora; se añadirá cuando se sepa el fin de la Fase 3 (`-CaducidadAuditor`).
- `recepcion.bcn` **no** entra en G_Sede_Barcelona, para que no herede la modificación de Comun\Sedes\Barcelona (P-43 frente a P-44).

**Desfase:** Sí, adelanto (dentro de D-02): las cuentas especiales estaban previstas para la sesión 5 (1/12).

### 2026-11-16 (noche, 3) · Fuera de horario · Oriol

**Hecho:**
- `02-alta-usuarios.ps1` v2.2 ejecutado en DC01 (VirtualBox): **funciona**. Usuarios, cuentas adm., grupos de política y políticas de contraseña creados.
- **Carpetas de trabajo en DC01:**

  ```
  C:\
  ├── CiberNova\                          (creada a mano)
  │   └── usuarios_cibernova.csv          CSV original del proyecto (UTF-8, separador ;), sin abrir ni guardar con Excel
  │
  └── CiberNova-Privado\                  (la crea el script 02 la primera vez que se ejecuta)
      ├── CredencialesIniciales.xml       contraseñas iniciales cifradas (DPAPI)
      └── logs\
          ├── alta_usuarios_AAAAMMDD_HHMMSS.log         un registro por cada ejecución del script 02
          └── cuentas_especiales_AAAAMMDD_HHMMSS.log    un registro por cada ejecución del script 03
  ```

  - `C:\CiberNova`: carpeta de trabajo. El script 02 busca el CSV exactamente en `C:\CiberNova\usuarios_cibernova.csv`. Los scripts se ejecutaron desde el escritorio del Administrador (`C:\Users\Administrador\Desktop`); se recomienda tenerlos también en `C:\CiberNova` junto al CSV. **[PENDIENTE DE CONFIRMAR]:** si los scripts se han copiado ya a `C:\CiberNova`.
  - `C:\CiberNova-Privado`: almacén privado. El script le quita los permisos heredados y solo deja acceso a la cuenta que lo ejecuta (Administrador), a SYSTEM y al grupo Administradores.
  - `CredencialesIniciales.xml`: contraseñas iniciales generadas por los scripts, cifradas con DPAPI (`Export-Clixml`); solo se pueden leer con la misma cuenta en el mismo equipo. Contiene 95 cuentas tras el script 02 (89 empleados + 6 adm.) y 101 tras el script 03 (+ recepcion.bcn, auditor.ext y las 4 svc_).
  - `logs`: registro completo de cada ejecución (`Start-Transcript`); no contiene contraseñas. Es el fichero a consultar si un script falla.
  - **Ninguna de las dos carpetas se sube al repositorio ni a Drive** (`C:\CiberNova-Privado` contiene las credenciales cifradas).

**Evidencias:** capturas del resumen, de las horas de inicio de sesión de izan.moreno (L-V 8:00-15:00) y de G_Admin_Sistemas en Admins. del dominio, añadidas a la memoria el 16/11.

**Desfase:** No.

### 2026-11-16 (noche, 2) · Fuera de horario · Oriol

**Hecho:**
- Ejecución de `02-alta-usuarios.ps1` v2.1: ya no hay error de sintaxis, pero la comprobación previa se detuvo:
  `FALTA -> Grupo: G_Politica_15`, `FALTA -> Grupo: G_Admin_Sistemas` y *"Faltan OU o grupos. Ejecuta primero 01-crear-ou-grupos.ps1"*. No se creó ningún usuario.
- Se volvió a ejecutar `01-crear-ou-grupos.ps1`: terminó bien, pero sin crear esos dos grupos.

**Problemas y soluciones:**
- **Causa:** el `01-crear-ou-grupos.ps1` del escritorio de DC01 es la **versión 1** (lo delata su salida: "CREACION DE GRUPOS GLOBALES" y "FASE 1 FINALIZADA"). En la v1, `G_Politica_15` y `G_Admin_Sistemas` los creaba el script 02; en la v2 se pasaron al 01, y la comprobación previa del 02 v2.1 los exigía.
- **Solución (02 v2.2):** el script 02 crea él mismo `G_Politica_15` y `G_Admin_Sistemas` si faltan (son grupos que solo usa este script), en lugar de detenerse. Así funciona con cualquier versión del 01. Probado con Active Directory simulado reproduciendo el estado de DC01 (sin esos dos grupos): los crea, da de alta los 89 empleados y las 6 cuentas adm., y una segunda ejecución no crea nada nuevo.
- **Medida para que no vuelva a pasar:** sustituir los scripts del escritorio por los del repositorio y comprobar la versión en la cabecera de cada script (`# Version:`) antes de ejecutarlo.

**Desfase:** No.

### 2026-11-16 (noche) · Fuera de horario · Oriol

**Hecho:**
- Ejecución en DC01 (VirtualBox) de `01-crear-ou-grupos.ps1`: correcto, OU y grupos creados.
- Ejecución de `02-alta-usuarios.ps1`: **error de sintaxis**; no llegó a ejecutarse nada (no se creó ningún usuario).

**Problemas y soluciones:**
- **Problema:** PowerShell mostraba errores de análisis antes de empezar:
  - `Token 'G_")) { ...' inesperado en la expresión o la instrucción` (línea 537).
  - `Falta la cadena en el terminador: "` y `Falta la llave de cierre "}"`.
- **Causa:** la línea `$GruposAdicionales.Trim() -notin @("-", "—")` contiene un **guion largo (—)**, que no es un carácter ASCII. El fichero estaba guardado en UTF-8 **sin BOM**, y Windows PowerShell 5.1 lee esos ficheros como Windows-1252. El guion largo (bytes `E2 80 94`) se lee entonces como `â€”`, y PowerShell trata el carácter `”` como unas **comillas de cierre**. A partir de ahí todas las comillas del fichero quedan descuadradas: la cadena se cierra antes de tiempo y el texto `"G_` se interpreta como el inicio de otra cadena; de ahí el "token inesperado" y el "falta el terminador".
- **Comprobación:** se reprodujo el mismo error leyendo el fichero como Windows-1252, igual que hace Windows PowerShell 5.1.
- **Además:** el fichero ejecutado usaba el parámetro `-UsuarioAD`, que es de la **versión 1** del script; la v2 ya no lo usa. Hay que usar siempre la última versión del repositorio.
- **Solución (v2.1):** el script es ahora **100 % ASCII**: el guion largo se escribe como `[char]0x2014` y las tildes de los nombres de departamento con su código (`[char]0x00F3` = ó, `[char]0x00ED` = í). Así funciona aunque se guarde sin BOM o se copie y pegue desde el navegador. Probado: 0 errores leyéndolo como Windows-1252 y como UTF-8, y la prueba completa con Active Directory simulado sigue dando el resultado esperado (89 empleados + 6 adm., departamentos con tildes correctas, horario de becarios correcto).
- **Lección aprendida:** en los scripts de Windows, nada de caracteres fuera de ASCII en el código (tildes, eñes, guiones largos, comillas tipográficas). Si hacen falta en los datos, se escriben con `[char]0x....`. Cuidado al copiar código desde Google Docs, que cambia las comillas rectas `"` por tipográficas `“ ”`.

**Desfase:** No.

**Siguiente paso:** ejecutar `02-alta-usuarios.ps1` v2.1 en DC01 y hacer las capturas (resumen final y horas de inicio de sesión de izan.moreno).

### 2026-11-16 (tarde) · Fuera de horario · Max y Oriol

**Hecho:**
- Script de alta de usuarios v1: daba error al ejecutarlo en DC01. Revisado y corregido (v2.0) junto con el script de OU y grupos. Probados con Active Directory simulado: sin errores, idempotentes y con los resultados esperados.
- Documentación actualizada con el estado real.

**Problemas y soluciones:**
- Problema: `Set-ADUser -LogonHours` no existe → el script se detenía en el primer becario. Solución: `-Replace @{logonHours=...}`. Lista completa de fallos y correcciones en la memoria técnica, apartado 5.2.
- Problema: las VMs Windows en Proxmox iban muy lentas (no era un error de instalación). Solución adoptada: VirtualBox + OVA. Pendiente comprobar las causas probables (guía del hipervisor, apartado 9).

**Decisiones:**
- "WEB01" (máquina de un inicio de proyecto anterior) se adapta a LNX01 (192.168.202.28); la .25 queda para FS01.
- DC02 se creará con una instalación limpia de Windows Server, nunca clonando DC01.

**Confirmado:** DC01 sigue en VirtualBox; DC02 sin montar; VMs Ubuntu creadas en Proxmox; Proxmox VE 9.2.21, nodo `PROC`.

**Desfase:** No (dentro de D-01 y D-02).

**Siguiente sesión (17/11):**
- Ejecutar los scripts v2 en DC01 si no se ha hecho en casa, con capturas del resumen y del horario de izan.moreno.
- Adaptar WEB01 a LNX01.

### 2026-11-16 (mañana) · Fuera de horario · Max y Oriol

**Hecho:**
- Revisión de la memoria del proyecto (Google Docs) y traspaso de su contenido al repositorio: guía del hipervisor, memoria técnica, inventario y scripts.
- Replanificación del calendario por los desfases D-01 y D-02.

**Problemas detectados en la revisión:**
- En la memoria la IP del host aparece como /24, pero la red del aula es /22: con /24 la puerta de enlace queda fuera de la red. Comprobar la máscara real.
- La contraseña del Administrador de DC01 y DC02 estaba escrita en claro en la memoria (y era la misma en los dos). Se ha quitado; hay que cambiarla.
- La VM Ubuntu "WEB01" usa 192.168.202.25, que en el diseño es FS01.
- En la exportación del script aparece "OU=Cuentasespeciales" (sin espacio) mientras que la OU se crea como "Cuentas especiales". Comprobar en el script original.
- El cálculo del horario de los becarios (`logonHours`) hay que comprobarlo en la consola de AD.

**Decisiones:**
- Se adopta la estructura de OU creada en DC01 en lugar de la propuesta del diseño (motivo: ya está hecha y cumple los requisitos). Queda pendiente decidir las OU Equipos y Servidores.
- **Red plana sin VLAN en la Fase 1** (motivo: no lo exige ningún documento del proyecto; montar VLAN con un firewall redundante pediría 2 VMs más y tiempo que no tenemos). Se compensa con el firewall de cada servidor y mínimo privilegio, y la segmentación con VLAN queda prevista como remediación de la Fase 3. Justificación completa en el documento de diseño, apartado 3.11.

**Desfase:** Sí (D-01 y D-02).

**Siguiente sesión (17/11):**
- Comprobaciones del host (`lsblk`, `ip -br link`, `ip -br addr`, `pveversion`) y primera importación de OVA.
- Preguntar al profesorado: ¿se permite un DHCP propio en la red del aula? ¿Se esperan VLAN en la Fase 1?

### 2026-11-13 · Fuera de horario · Max y Oriol

**Hecho:**
- Análisis del enunciado, la presentación y el Anexo I.
- Diseño inicial: ecosistema mixto, 8 VMs en 4 parejas, plan de direccionamiento sobre el rango .23–.33.
- Calendario inicial de la Fase 1 (8 sesiones hasta el 15/12).

**Decisiones:**
- Proxmox solo como plataforma de virtualización; cada VM se trata como servidor físico (motivo: enfoque de laboratorio realista).
- Ubuntu Server 24.04 en lugar de Debian (motivo: familiaridad; versión soportada por SQL Server 2025).
- SQL Server 2025 Enterprise Developer con Always On AG en lugar de MariaDB Galera.
- Apache en lugar de nginx (motivo: familiaridad y `.htaccess`).
- Bareos con dos servidores para backups en lugar de Proxmox Backup Server.
- Reparto: Max → Linux, Oriol → Windows.

**Desfase:** No.

### Antes del 13/11 · Fuera de horario y en el aula · Max y Oriol

> **[PENDIENTE DE CONFIRMAR]:** fechas exactas de cada paso.

**Hecho:**
- Pendrive de instalación de Proxmox con Rufus.
- RAID 10 con los 4 discos desde la configuración del servidor.
- Instalación de Proxmox (3 intentos) y reinstalación posterior con otra versión.
- Script *PVE Post Install* (repositorios No-Subscription, quitar aviso de suscripción, actualizar).
- DC01 en VirtualBox: IP fija .23, nombre, rol AD DS, nuevo bosque `cibernova.local`.
- DC02 instalado; ping correcto entre DC01 y DC02.
- VM Ubuntu "WEB01" creada (usuario `admincibernova`).
- Scripts de OU y grupos y de alta de usuarios.

**Problemas y soluciones:**
- Instalación de Proxmox, 1.er intento: error del instalador **[PENDIENTE DE CONFIRMAR: mensaje]** → reintento.
- 2.º intento: DNS y puerta de enlace mal configurados → se revisó la red y se reinstaló (3.er intento correcto).
- No se podía instalar Windows Server en Proxmox → reinstalación de Proxmox con la versión que usaban otros grupos y, después, cambio a VirtualBox + OVA (D-01).
- La instalación del rol de AD DS tardó mucho, pero funcionó a la primera.

**Decisiones:**
- Proxmox VE por ser gratuito, con gestión centralizada y preparado para clúster.
- Construir las VMs en VirtualBox e importarlas como OVA.
- Aplazar carpetas personales, cuotas y perfiles (dependen del servidor de ficheros), `recepcion.bcn` (falta el nombre del equipo de recepción) y las cuentas de servicio (valorar gMSA cuando estén los servidores).
