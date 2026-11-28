# Lista de tareas de la Fase 1 (control de requisitos)

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Versión:** 1.12 · 27/11/2026, noche · **V22 definitiva (fusión del 28/11).** Max (27/11 fuera de horario: ufw en LNX02, SFTP con mismas claves y rsync, Bareos con copia a BKP02 y restauración con BKP01 caída, calendario, copia de BKP01, Director en espera, Portal CiberNova, WEB-03, Kea HA en red aislada: LNX-06, DB-05, DB-06, WEB-01, WEB-03, SFTP-02, BKP-01, BKP-03, BKP-04, BKP-05, PR-06, DHCP-01 ✅; DHCP-02, SFTP-03, BKP-02 parciales) · v1.11 · 27/11/2026 (Oriol, tarde: los cuatro Windows importados en Proxmox, 123–126, AD-11b y FS-01 siguen parciales hasta arrancarlos; red aislada `vmbr1` para el DHCP, DHCP-01 ✅ y DHCP-02 parcial; HV-08 con SATA/E1000) · v1.10 · 27/11/2026 (V21 conjunta. **Oriol, 26–27/11:** permisos P-01 a P-44 aplicados con los scripts 06 y 96; carpetas personales y cuotas con el script 07; Perfiles en DFS; GPO de unidades y de redirección; OVA de los Windows exportadas: FS-03 a FS-11, FS-13 y GPO-08 ✅, FS-12, GPO-01/02/04, AD-11b y FS-01 parciales. **Max,** sesión 4 Linux, 26/11: base de datos en el AG y conmutación manual y automática probadas; Apache + PHP-FPM con los drivers de SQL Server; Apache en Pacemaker con la VIP; usuario `web_cibernova`; firewall `ufw` en LNX01 y BKP01: DB-04, WEB-02 y WEB-04 ✅, PR-04 parcial, LNX-06 y DB-06 parciales) · v1.9 · 24/11/2026 (FS02 unida y configurada, DFS-R FS01 ↔ FS02 probada: DOM-01 ✅, FS-02 y FS-08 ✅ en VirtualBox, FS-03 parcial) · v1.8 · 24/11/2026 (AG `sqlag_cibernova` en Pacemaker con VIP .27: DB-03 y HA-03 ✅, DB-04 parcial; FS01: carpetas del espacio de nombres, FS-02 parcial) · v1.7 · 23/11/2026 (FS01 en VirtualBox: unida al dominio, disco de datos, roles, espacio de nombres con ABE y cuatro recursos compartidos; DOM-01 y FS-01 parciales, FS-08 parcial) · v1.6 · 23/11/2026 (clúster Pacemaker de 3 nodos y fencing: HV-07, HA-01 y HA-02 ✅) · v1.5 · 19/11/2026 (sesión 2 Linux: SQL Server configurado en LNX01, LNX02 y BKP01; BKP02 creada) · v1.4 · 19/11/2026 (DC02 promovido y comprobado en VirtualBox; reenviadores de DC02) · v1.3 · 19/11/2026 (reenviadores corregidos, revisión general de documentos, DC02 en VirtualBox)

> **Para qué sirve:** es la lista de todo lo que pide la práctica y en qué punto está. **Regla:** solo se marca ✅ lo que Max u Oriol han confirmado que está hecho (con su captura o comprobación). Todo lo demás está pendiente. Antes de dar por terminado un servicio o una máquina, se revisa esta lista.
>
> **Fuentes:** enunciado `0379_PROYECTO_INTERMODULAR.pdf` (Fase 1, normas y evaluación), `Proyecto_Intermodular_-_Anexo_1.pdf` (usuarios, grupos, carpetas, permisos, pruebas) y la presentación del proyecto.
>
> **Fecha límite:** todo lo que deba estar en la entrega tiene que estar **subido a GitHub el viernes 4/12/2026** (después no se puede modificar el repositorio).

**Leyenda:** ✅ hecho (confirmado) · ⏳ pendiente · ❓ falta una decisión o un dato (no se puede empezar sin él) · 📸 necesita captura

---

## 0. Resumen por servicio obligatorio (enunciado, Fase 1)

| Servicio que pide el enunciado | Configurado | Redundante | Prueba de caída 📸 |
|---|---|---|---|
| Plataforma de virtualización (Proxmox) | ✅ Instalado (9.2.21, nodo PROC) | Host único: riesgo aceptado | — |
| Identidades (AD DS) | ✅ DC01 (OU, grupos, usuarios, cuentas especiales) · ✅ DC02 promovido (19/11, en VirtualBox) | ✅ Replicación DC01 ↔ DC02 | ⏳ |
| DNS | ✅ DC01 (interfaz gráfica + reenviadores 8.8.8.8 / 1.1.1.1) | ✅ DC02 (zonas replicadas, reenviadores 8.8.8.8 / 1.1.1.1, DNS cruzado) | ⏳ |
| DHCP | ✅ Kea 2.4.1 en LNX01 y LNX02, solo en la red aislada `vmbr1` (10.10.10.0/24, `ens19`), *pool* .100–.200 (27/11) | ✅ Kea HA hot-standby (LNX01 primario, LNX02 en espera), `ha-heartbeat` OK (27/11) | ⏳ PR-05 con VM de prueba en `vmbr1` |
| Servidor web | ✅ Apache 2.4 (`mpm_event`) + PHP-FPM 8.3 + `sqlsrv`/`pdo_sqlsrv` en LNX01 y LNX02 (26/11) · ✅ **Portal CiberNova** (intranet de incidencias, BD `cibernova_portal` en el AG, 27/11) | ✅ Apache como recurso de Pacemaker con la VIP .27 y la réplica principal (26/11) · ✅ código igual en los dos nodos (`web-sync.sh`, 27/11) | ✅ Conmutación con toda la cadena: ≈ 29 s sin servicio, sin pérdida de datos (26/11) · ✅ conmutación con el portal (27/11) |
| FTP/SFTP | ⏳ sshd con *chroot* para el grupo del dominio (espera al dominio) | ✅ Mismas claves de host en LNX01 y LNX02 y `/srv/sftp` copiado cada minuto desde el nodo con la VIP (27/11) · VIP .27 | ⏳ |
| Base de datos | ✅ SQL Server 2025 configurado (19/11): Enterprise Developer en LNX01/LNX02, Express en BKP01, Always On activado | ✅ AG `sqlag_cibernova` en Pacemaker con VIP .27 (24/11) y base de datos `cibernova_pruebas` sincronizada (26/11) | ✅ Conmutación manual y caída de LNX01 (`qm stop`): ≈ 36 s sin servicio, RPO 0 (26/11) |
| Ficheros con DFS | ✅ FS01 y FS02 (23–24/11, en VirtualBox): espacio de nombres `\\cibernova.local\empresa` con ABE y cuatro carpetas · ⏳ permisos NTFS y cuotas | ✅ DFS-N con dos servidores + DFS-R (4 grupos, prueba OK) · ⏳ prioridad de FS01 en las referencias | ⏳ |
| Usuarios y grupos con permisos y accesos | ✅ usuarios y grupos globales · ⏳ grupos `DL_`, permisos, carpetas, GPO | — | 15 pruebas del Anexo I ⏳ |
| Backups | ✅ Bareos 25.1.3: Director + catálogo PostgreSQL en BKP01; copias de LNX01, LNX02 (con las BD del AG) y BKP01; calendario en horario de sesión (27/11) · ⏳ agentes de Windows | ✅ Copia a BKP02 (regla 3-2-1) · ✅ Director en espera en frío en BKP02 (27/11) | ✅ Restauración con SHA-256 y restauración desde BKP02 con BKP01 caída (PR-06, 27/11) · ⏳ activación del Director en BKP02 |

---

## 1. Plataforma y host (Proxmox)

| ID | Tarea | Quién | Estado | Notas / evidencia |
|---|---|---|---|---|
| HV-01 | Instalar Proxmox VE, IP 192.168.202.3, `vmbr0` | Ambos | ✅ | Guía del hipervisor; capturas en la memoria |
| HV-02 | Script *PVE Post Install* | Ambos | ✅ | |
| HV-03 | Comprobar RAID 10 por hardware y almacenamiento (`lsblk`, `pvesm status`) | Max | ✅ | 17/11: un disco `sda` de 1,6 TB (RAID 10 por hardware), `local-lvm` LVM-thin 1,5 TB, `local` 98 GB (~24 GB libres) |
| HV-04 | NIC cableadas (`ip -br link`); si hay dos, bond active-backup | Max | ❓ | 17/11: solo `nic0` con cable (punto único de fallo aceptado). Preguntar si se puede cablear otra (Q-06). `vmbr1` sin uso conocido |
| HV-05 | Máscara /22 en `vmbr0` | Max | ✅ | 17/11: `vmbr0` = 192.168.202.3/22 |
| HV-06 | Orden de arranque de las VMs (DC → BKP → FS → LNX → clientes) y arranque automático | Ambos | ⏳ | `qm set <id> --startup order=…` |
| HV-07 | Usuario de Proxmox con permisos mínimos para `fence_pve` | Max | ✅ | 23/11: `fence@pve` con rol `FenceCiberNova` (`VM.PowerMgmt` + `VM.Audit`) solo sobre `/vms/128`–`130`. 📸 `proxmox_usuario-fence` |
| HV-08 | Rendimiento de Windows en Proxmox (VirtIO, agente QEMU) | Oriol | ⏳ | 27/11: importados con disco SATA y tarjeta E1000 y agente QEMU activado en Proxmox. Falta instalar los controladores VirtIO y el agente dentro de Windows y cambiar disco y tarjeta [PENDIENTE DE CONFIRMAR] |
| HV-09 | Copia de las VMs (norma 2 del enunciado: "copias actualizadas de su infraestructura") | Max | ❓ | 27/11: no es obligatoria en la Fase 1 (la norma 2 la pide "especialmente antes de las fases de pentest") y no cabe en `local` (≈ 24 GB libres; ≈ 1.290 GB asignados en `local-lvm`). Pendiente de preguntar al profesorado por un disco externo o almacenamiento del centro. Hacer antes de la Fase 3 |

## 2. Identidades: Active Directory (Oriol)

| ID | Tarea | Estado | Notas / evidencia |
|---|---|---|---|
| AD-01 | Bosque `cibernova.local` en DC01 (.23) | ✅ | 16/11 |
| AD-02 | 23 OU (script 01 v2.1) | ✅ | 📸 hecha |
| AD-03 | 27 grupos globales (departamento, sede, transversales, becarios, política) | ✅ | 📸 hecha |
| AD-04 | Políticas de cuentas: general (12, complejidad, historial 10, 90 días, bloqueo 5/15 min) y PSO de 15 caracteres | ✅ | Script 02 v2.2 |
| AD-05 | Alta de los 89 empleados por script idempotente con cambio de contraseña obligatorio | ✅ | Script 02 v2.2, 📸 hecha |
| AD-06 | Becarios: caducidad 30/06/2027 y horario L-V 8-15 | ✅ | Script 02 |
| AD-07 | 6 cuentas `adm.` en Admins. del dominio (cuentas personales de Sistemas estándar) | ✅ | Script 02 |
| AD-08 | Cuentas especiales `recepcion.bcn`, `auditor.ext`, `svc_*` con sus restricciones | ✅ | Script 03, 26 comprobaciones OK |
| AD-09 | Borrar la OU vacía `Cuentasespeciales` (sin espacio) si quedó de la v1 | ✅ | Revisado el 18/11 (confirmado por Max) |
| AD-10 | Exportar DC01 a OVA e importarlo en Proxmox (VMID 123, IP .23 de nuevo) | ⏳ | **No se hizo en la sesión 1 (D-05)**; primero en la sesión 2. Si el asistente falla, método manual · 📸 · la copia de VirtualBox no se vuelve a encender |
| AD-11 | DC02: instalación limpia y promoción con DNS y catálogo global **en VirtualBox** junto a DC01 (decisión del 19/11) | ✅ | 19/11 (guía 07, apartado 2). Hora desde DC01, GPO de dominio aplicadas, FSMO en DC01 · 📸 FSMO y licencia |
| AD-11b | Exportar DC01 y DC02 a OVA e importarlos en Proxmox (123 y 124, DC01 primero, IP de nuevo) | ⏳ Parcial | **OVA exportadas e importadas el 27/11 (Oriol, memoria 2.9)**: 123 y 124 creadas y paradas; falta arrancar DC01, IP de nuevo y comprobar · De uno en uno (≈ 24 GB libres en `local`) · no volver a encender las copias de VirtualBox · 📸 `replsummary` y `nslookup` en Proxmox |
| AD-12 | Replicación DC01 ↔ DC02 (`repadmin /replsummary`, usuario de prueba) | ✅ | 19/11: 0 errores en las dos direcciones, 5 particiones correctas, SYSVOL compartido y en estado 4, usuario de prueba replicado. `dcdiag`: solo avisos DFSREvent/SystemLog de la promoción (16:27) · 📸 |
| AD-13 | Fuente de hora del PDC (DC01) | ✅ | 18/11: `hora.roa.es` y `es.pool.ntp.org` con `w32tm` (confirmado por Max) |
| AD-14 | Caducidad de `auditor.ext` al final de la Fase 3 | ❓ | Fecha sin comunicar |
| AD-15 | Uso real de `svc_web` y `svc_bbdd` en los servicios Linux (mínimo privilegio) | ⏳ Parcial | 26/11: la web entra en SQL Server con el login **`web_cibernova`** (SQL Server, no del dominio), creado en LNX01 y LNX02 con el **mismo SID** y solo con `db_datareader` + `db_datawriter` en su base de datos (decisión de Max). Mejora prevista: cambiarlo por `svc_web` del dominio (autenticación de AD con *keytab*) cuando los DC estén en Proxmox. `svc_bbdd` sin uso decidido [PENDIENTE DE CONFIRMAR] |
| AD-16 | Evaluación de Windows: `slmgr /rearm` antes del ≈ 9/05/2027 | ⏳ | Fase 3; revisar también DC02, FS01, FS02 |
| AD-17 | Script de **movimientos de personal** (baja, cambio de departamento, alta, becario → júnior) | ⏳ | Anexo I ap. 11-12: se aplican cuando lo indique el profesorado |

## 3. DNS (Oriol)

| ID | Tarea | Estado | Notas / evidencia |
|---|---|---|---|
| DNS-01 | Zona `cibernova.local` integrada en AD; tarjeta de DC01 solo con 127.0.0.1; reenviadores 8.8.8.8 y 1.1.1.1 | ✅ | 16/11 y 18/11 (la red del aula intercepta el DNS: bitácora 18/11) |
| DNS-02 | Configurar el DNS: actualizaciones seguras, sin transferencias, zona inversa, registros fijos de los Linux, limpieza | ✅ | Script 04 v1.0 ejecutado el 17/11 y deshecho con `84-deshacer-dns.ps1`; el 18/11 se volvió a configurar todo **por la interfaz gráfica** y se verificó (paso 8). Confirmado por Max |
| DNS-03 | Nombres de servicio hacia la VIP .27 (`www`, `sftp`, `sqlag`) | ✅ | Creados el 18/11 (nombres del diseño). El listener del AG se llamará `sqlag` |
| DNS-04 | DNS cruzado entre DC (DC01 → .24 + 127.0.0.1; DC02 → .23 + 127.0.0.1) y reenviador en DC02 | ✅ | 19/11: DNS cruzado (`ipconfig /all`). Reenviadores: DC02 → 8.8.8.8 y 1.1.1.1 (quitado DC01, que puso el asistente); DC01 → quitado DC02. Motivo: evita bucles y dependencia mutua. `nslookup` directo e inverso de lnx01 contra 127.0.0.1 en DC02 correcto |
| DNS-05 | `93-comprobar-dns.ps1 -Servidor 192.168.202.24`: DC02 responde lo mismo | ⏳ | 📸 |
| DNS-06 | Verificación final: `nslookup` (directa, inversa, SRV, Internet) y `dcdiag /test:dns` | ✅ | Confirmado por Max el 18/11 (paso 8 de la guía gráfica) |

## 4. Unión al dominio (todas las máquinas)

| ID | Tarea | Quién | Estado | Notas |
|---|---|---|---|---|
| DOM-01 | FS01 y FS02 en la OU Servidores | Oriol | ✅ | **FS01 (23/11) y FS02 (24/11), en VirtualBox:** cuenta preconfigurada en `OU=Servidores,OU=CiberNova`, unión por interfaz gráfica, `gpresult` con las GPO de servidores 📸 |
| DOM-02 | LNX01, LNX02, BKP01, BKP02 con realmd + SSSD, solo `G_Admin_Sistemas` | Max | ⏳ | `realm list` 📸 · necesita Internet para `apt` ❓ |
| DOM-03 | CLI01 y CLI02 en la OU Equipos | Oriol | ❓ | ¿uno se llama `BCN-RECEPCION`? ¿qué sede? ¿Windows 11 Pro/Education? |
| DOM-04 | Host Proxmox (PROC) | — | ❓ | Propuesta: no se une |
| DOM-05 | `Get-ADComputer` con todas las máquinas en su OU | Oriol | ⏳ | 📸 |

## 5. Servidor de ficheros con DFS (Oriol)

| ID | Tarea | Estado | Notas / evidencia |
|---|---|---|---|
| FS-01 | FS01 (.25) y FS02 (.26): instalación limpia (VirtualBox → OVA → Proxmox), disco de datos | ⏳ Parcial | **FS01 ✅ en VirtualBox (23/11):** 2 vCPU, 4 GB, sistema 50 GB, **datos 150 GB dinámico** (D: `Datos`, GPT, NTFS), confirmado por Max y Oriol. **FS02 ✅ en VirtualBox (24/11)** con los mismos recursos. **OVA exportadas e importadas el 27/11** (125 y 126, `sata0` 50 G + `sata1` 150 G, memoria 2.9); falta arrancarlas y comprobar DFS-R |
| FS-02 | Espacio de nombres DFS de dominio `\\cibernova.local\empresa` con los nombres exactos del Anexo I (ap. 8) | ✅ (VirtualBox) | Raíz creada el 23/11 (`Domain V2`, modo 2008, ABE) con destino FS01 📸. Recursos `Personales$`, `Departamentos$`, `Proyectos$`, `Comun$` creados. **Carpetas del espacio de nombres creadas el 24/11** (`Comun`, `Departamentos`, `Personales`, `Proyectos` → `\\FS01\<Carpeta>$`, las cuatro `Online`) 📸. **FS02 como segundo servidor del espacio de nombres (24/11)** 📸 |
| FS-03 | Replicación DFS-R FS01 ↔ FS02; FS01 con prioridad en las referencias | ✅ (VirtualBox) | **DFS-R ✅ (24/11):** cuatro grupos de replicación, FS01 miembro principal, malla completa; prueba con `prueba-replicacion.txt` FS01 → FS02 📸. **26/11:** destinos de FS02 como *Último de todos los destinos* (`GlobalLow`) 📸, borrado replicado 📸, informe de estado de DFS-R con 0 errores 📸. Quinta carpeta `Perfiles` con la misma configuración |
| FS-04 | Estructura de carpetas creada por script | ✅ (VirtualBox) | `06-carpetas-permisos.ps1` v1.3 (26/11): 50 carpetas del Anexo I ap. 8 📸; replicadas a FS02 |
| FS-05 | **Matriz de permisos** P-01 a P-44 (carpetas en filas, grupos en columnas) | ✅ | `docs/fase1/08-matriz-permisos.md` v1.0 (26/11), simulada con los 89 usuarios del CSV: 0 errores · visto bueno de Max [PENDIENTE DE CONFIRMAR] |
| FS-06 | Grupos `DL_<Carpeta>_<Nivel>` y anidamiento `G_` → `DL_` (AGDLP) | ✅ | 63 grupos `DL_` + `G_RRHH_Nominas_Consulta` (script 06, 26/11); script 96 v1.2: 0 errores en FS01 y FS02 📸 · falta el diagrama de anidamientos (DOC-05) |
| FS-07 | Permisos NTFS según la matriz; decisión recurso compartido vs NTFS justificada | ✅ (VirtualBox) | **Decisión (23/11, visto bueno de Max):** recurso compartido con *Usuarios autentificados* Control total y permisos reales solo en NTFS (bitácora 23/11). **NTFS aplicados (26/11)** con el script 06 v1.3 (50 ACL) y comprobados con el 96 v1.2 en FS01 y FS02 (0 errores) 📸 · ejemplo manual de `RRHH\Nominas` por interfaz gráfica 📸 |
| FS-08 | Enumeración basada en acceso (ABE) en todos los recursos | ✅ | ✅ En la raíz DFS y en los cuatro recursos de FS01 (23/11) y de FS02 (24/11), `AccessBased` 📸 · pruebas 3, 5, 14 |
| FS-09 | Depósito `RRHH\Buzon_Documentacion` (P-10) e `Comun\Intercambio` (P-41) con CREATOR OWNER | ✅ (configurado) | Niveles D e I del script 06; `icacls` de Intercambio comprobado (26/11) · pruebas 7 y 8 pendientes (clientes) |
| FS-10 | Becarios con permisos reducidos sin denegaciones genéricas (P-17, P-21, P-31) y sin acceso nunca a Proyectos (P-38) | ✅ (configurado) | Grupos `G_Becarios_*` propios y una sola denegación (`DL_Proyectos_Denegar`), justificado en el documento 08 · prueba desde cliente pendiente |
| FS-11 | Auditoría de acceso en `Nominas`, `Expedientes` y `Proyectos\Sanitario`, también para Sistemas (P-11, P-39) | ✅ (configurado) | SACL (Todos, éxito y error) con el script 06; `auditpol` en FS01 → *Aciertos y errores* 📸 · prueba 15 pendiente |
| FS-12 | Carpetas personales `Personales\<usuario>` **creadas por el script de alta**, solo el usuario con Modificar | ⏳ Parcial | **89 carpetas creadas (26/11)** con `07-personales-cuotas-perfiles.ps1` (solo el usuario con Modificar; H: en AD) 📸 · falta que el script de alta (02 v2.3) llame al 07 en cada alta [PENDIENTE DE CONFIRMAR con Max] |
| FS-13 | Cuotas FSRM: 2 GB general, 5 GB Desarrollo y Sistemas, 500 MB becarios, aviso al 90 % y bloqueo | ✅ (configurado) | Script 07 (26/11): 3 plantillas con límite estricto y aviso al 90 % (evento); 89 cuotas en FS01 y 89 en FS02 📸 · aviso solo como evento [PENDIENTE DE CONFIRMAR] · prueba 12 pendiente |
| FS-14 | (Valorable) vaciado automático de `Intercambio` (archivos de más de 30 días) | ⏳ | Tarea programada o FSRM |
| FS-15 | `svc_backup` con privilegio de copia en FS01/FS02 | ⏳ | GPO |

## 6. GPO, perfiles y unidades de red (Oriol)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| GPO-01 | Perfil **móvil** para Dirección y Comercial | ⏳ Parcial | `ProfilePath` en los 16 usuarios "Movil" (script 07) y carpeta `Perfiles` en DFS con FS01 y FS02 (26/11) 📸 · prueba 9 pendiente |
| GPO-02 | Perfil local con **redirección** de Documentos y Escritorio para el resto | ⏳ Parcial | `GPO_Usuarios_Redireccion` (26/11): `G_Sede_*`, denegada a `G_Direccion` y `G_Comercial`; Documentos y Escritorio → `Personales\%USERNAME%`, sin derechos exclusivos 📸 · falta probar desde cliente |
| GPO-03 | Perfil **obligatorio** para `recepcion.bcn` | ⏳ | Prueba 10 |
| GPO-04 | Unidades H:, G:, P: (solo con acceso a algún proyecto) y S: (también recepcion) | ⏳ Parcial | H: en la cuenta de AD (script 07); `GPO_Usuarios_Unidades` (26/11): G: (`G_Sede_*`), P: (`DL_Proyectos_L`), S: (`DL_Comun_C`) con destino por grupo 📸 · falta probar desde cliente |
| GPO-05 | Denegar inicio de sesión interactivo a `G_Cuentas_Servicio` | ✅ | `GPO_Dominio_CuentasServicio` (script 05 v1.1, 18/11), aplicada en DC01; script 94: 25 OK |
| GPO-06 | Cuentas `adm.` sin inicio de sesión en equipos de usuarios | ⏳ | `GPO_Equipos_SinCuentasAdm` creada y vinculada (18/11); falta comprobarla en CLI01/CLI02 |
| GPO-07 | Firewall de Windows por GPO (compensación de la red plana) | ✅ | `GPO_Dominio_Firewall` (18/11), aplicada en DC01 (3 perfiles activados); falta comprobarla en el resto al unirlos |
| GPO-08 | Auditoría avanzada de acceso a archivos en FS01/FS02 | ✅ | `GPO_Servidores_Auditoria` creada y vinculada (18/11); **aplicada en FS01 y FS02** (`gpresult`, 23 y 24/11). SACL de las carpetas aplicadas el 26/11 (FS-11) |

## 7. Clientes de prueba (Oriol)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| CLI-01 | Instalar CLI01 (.32) y CLI02 (.33) con Windows 11 que permita dominio | ⏳ | ❓ nombres y edición |
| CLI-02 | Unirlos al dominio en su OU | ⏳ | DOM-03 |

## 8. Servidores Linux: base (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| LNX-01 | LNX01 instalada de cero en VirtualBox y exportada a OVA | ✅ | 17/11, D-03 |
| LNX-02 | Importar LNX01 en Proxmox (VirtIO), IP .28 en `ens18` | ✅ | 17/11, VMID 128, importación manual (el asistente falló); netplan fijo e instantánea `base-limpia` |
| LNX-03 | WEB01 (usaba la .25 de FS01) | ✅ | Borrada el 17/11 con las demás VMs antiguas (100–107) |
| LNX-04 | LNX02, BKP01 y BKP02 con Ubuntu 24.04 | ✅ | LNX02 (129, .29) y BKP01 (130, .30) clonadas de LNX01 el 17/11 (opción A) y personalizadas (BKP01 el 18/11). BKP02 (131, .31) clonada el 19/11 de la instantánea `base-limpia` (sin SQL Server) y personalizada. Las cuatro con el mismo kernel (6.8.0-151). 📸 `*_personalizado`, `*_kernel*` |
| LNX-05 | IP fija, DNS .23/.24, hora con los DC en las cuatro | ⏳ | Guía 07, apartado 3.3 |
| LNX-06 | Firewall (ufw/nftables) solo con los puertos necesarios | ✅ | 26/11: `ufw` en LNX01 y BKP01. **27/11:** LNX02 con las mismas 15 reglas; BKP02 con 22/tcp y 9103/tcp (desde .30, y desde .28/.29 para restaurar). Reglas de Kea (67/udp y 8000/tcp) solo en `ens19` de LNX01 y LNX02. Ver `configs/linux/ufw/reglas-ufw.md` 📸 |
| LNX-07 | Salida a Internet para `apt` desde el rango .23–.33 | ✅ | 17/11 con LNX01 (DNS públicos en netplan porque el DNS del aula no responde) |

## 9. Base de datos: SQL Server 2025 AG (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| DB-01 | SQL Server 2025 Enterprise Developer en LNX01 y LNX02 | ✅ | 19/11: `mssql-conf setup` (opción 2), `hadr.hadrenabled 1` y Agente activado. `sqlcmd` → Enterprise Developer, `alwayson = 1`. 📸 `lnx0x_mssql-status`, `lnx0x_mssql-comprobacion` |
| DB-02 | SQL Server Express en BKP01 (réplica de solo configuración) | ✅ | 19/11: `mssql-conf setup` (opción 4) y `hadr.hadrenabled 1` (sin Agente: Express no lo incluye). `sqlcmd` → Express, `alwayson = 1`. Falta añadirla al AG como réplica de solo configuración (DB-03/04). 📸 `bkp01_mssql-*` |
| DB-03 | Always On AG con commit síncrono, endpoints con certificados | ✅ | 24/11: certificado `dbm_certificate` (hasta 31/12/2028) en los tres; *endpoints* 5022 con AES (`ALL` en LNX01/LNX02, `WITNESS` en BKP01); AG `sqlag_cibernova` (`EXTERNAL`), `lnx01`/`lnx02` síncronas y `bkp01` `CONFIGURATION_ONLY`, las tres `CONNECTED`. 📸 `*_endpoint`, `lnx01_crear-ag`, `lnx01_replicas-ag` |
| DB-04 | AG como recurso de Pacemaker, listener en la VIP .27 | ✅ | 24/11: `pacemakerLogin`, recurso `ag_cluster` y VIP .27. **26/11:** base de datos `cibernova_pruebas` (recuperación completa + copia) añadida al AG con *seeding* automático → `SYNCHRONIZED`/`HEALTHY` en LNX01 y LNX02; conmutación manual con `pcs resource move ... --promoted` (en los dos sentidos) y caída real de LNX01 (`qm stop 128`): conmutación automática con *fencing*, sin pérdida de datos. Punto de control del 1/12 cumplido (sin plan B) 📸 `2026-11-26_sesion04_*` |
| DB-05 | Base de datos de la aplicación web | ✅ | 27/11: `cibernova_portal` en el AG (`configs/linux/web/portal/cibernova_portal.sql` v1.0), `SYNCHRONIZED`/`HEALTHY` en lnx01 y lnx02; `web_cibernova` solo con `SELECT`/`INSERT`/`UPDATE` en `dbo.incidencias`; `backup_cibernova` con `db_backupoperator` 📸 |
| DB-06 | Acceso a la BBDD solo desde los nodos web y BKP01 | ✅ | 1433/tcp solo desde .28, .29 y .30 en LNX01, BKP01 (26/11) y LNX02 (27/11) 📸 |

## 10. Clúster Pacemaker + Corosync (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| HA-01 | Clúster `cibernova-g3` de **3 nodos (LNX01, LNX02, BKP01)** en unicast (knet), sin qdevice | ✅ | 23/11: 3 nodos `Online`, `Quorate: Yes` (3 votos, quórum 2). Decisión del 23/11: BKP01 es nodo porque aloja la réplica de solo configuración. 📸 `pcs-status-3-nodos`, `quorum` |
| HA-02 | Fencing `fence_pve` contra Proxmox | ✅ | 23/11: recurso `fence-proxmox` con `pcmk_host_map`. Prueba real: `pcs stonith fence lnx02` → reinicio correcto, quórum mantenido. 📸 `fence-lnx02-*` |
| HA-03 | VIP .27 junto al primario del AG | ✅ | 24/11: `virtualip` (`IPaddr2`, /22) con colocación `INFINITY` con la réplica `Promoted` y orden `promote → start` (`Mandatory`). `Started lnx01`, .27 en `ens18` de LNX01. 📸 `lnx01_pcs-status-vip` |

## 11. Web (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| WEB-01 | Decidir la aplicación web (debe usar SQL Server) | ✅ | 27/11 (Max): **interna y sencilla: Portal CiberNova**, intranet de incidencias de Sistemas (`index.php` v1.1, `/var/www/html/portal`, `640 root:www-data`). Alternativas: Moodle, WordPress/Joomla (sin SQL Server), web estática. Autenticación contra el AD desde Apache (`mod_authnz_ldap`) cuando estén los DC ⏳ 📸 |
| WEB-02 | Apache mpm_event + PHP-FPM + driver ODBC + `sqlsrv` en LNX01 y LNX02 | ✅ | 26/11: Apache 2.4.58 (`mpm_event`), PHP-FPM 8.3.6, `proxy_fcgi`, `sqlsrv` y `pdo_sqlsrv` 5.13.3 (PECL) en los dos nodos. Página `bbdd.php` que entra por la VIP con `web_cibernova` (credenciales en `/etc/cibernova/web.ini`, `640 root:www-data`, fuera de la carpeta web) 📸 |
| WEB-03 | Mismo contenido web en los dos nodos | ✅ | 27/11 (Max): `scripts/linux/web-sync.sh` v1.0 + cron cada minuto desde el nodo con la VIP; clave `/root/.ssh/web_sync` restringida con `rrsync` a `/var/www/html`. `web.ini` se mantiene a mano. Probado: fichero nuevo y borrado propagados 📸 |
| WEB-04 | Apache como recurso de Pacemaker con la VIP | ✅ | 26/11 (opción A, decisión de Max): recurso `apache` (`ocf:heartbeat:apache`, comprueba `server-status` cada 20 s), `apache2` quitado del arranque de systemd; colocación `INFINITY` con `virtualip`, orden `virtualip` → `apache` y `avoids bkp01`. Conmutación probada: la web sigue a la réplica principal 📸 |

## 12. SFTP (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| SFTP-01 | SFTP con chroot en LNX01 y LNX02 | ⏳ | |
| SFTP-02 | Quién usa el SFTP (usuarios de AD o locales) y qué carpeta | ✅ | 27/11 (Max): usuarios del dominio (grupo [PENDIENTE DE CONFIRMAR]), carpeta `/srv/sftp`. Se espera al dominio |
| SFTP-03 | Mismas claves de host SSH en los dos nodos (sin aviso tras conmutar) y mismos datos | ⏳ Parcial | 27/11: claves de host de LNX01 copiadas a LNX02 (misma huella); `sftp-sync.sh` v1.0 + cron cada minuto desde el nodo con la VIP, probado en los dos sentidos (RPO 1 min). Falta la prueba de caída del SFTP con usuarios del dominio 📸 |

## 13. DHCP (Oriol, 27/11; diseño de Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| DHCP-01 | Dónde funciona el DHCP | ✅ | **Red aislada `vmbr1`** (27/11): en la red del aula repartiría IP a cualquier equipo del centro mientras el servidor estuviera encendido. `vmbr1` venía creado por defecto, sin tarjeta física y sin uso (comprobado) |
| DHCP-02 | Kea HA hot-standby en LNX01/LNX02 | ⏳ Parcial | 27/11: `ens19` (10.10.10.28/.29) por Oriol; Kea 2.4.1 por Max (`configs/linux/kea/kea-dhcp4.conf` v1.1): solo `ens19`, *pool* .100–.200, 1 h, solo `domain-name`, HA hot-standby con escuchador HTTP integrado (8000/tcp), `max-unacked-clients` 0. `ha-heartbeat`: los dos en `hot-standby`. Falta PR-05. Los clientes CLI01/CLI02 siguen en la red del aula con IP fija 📸 |

## 14. Copias de seguridad: Bareos (Max, con Oriol para Windows)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| BKP-01 | Bareos Director + almacenamiento en BKP01; almacenamiento en BKP02 | ✅ | 27/11: Bareos 25.1.3, catálogo PostgreSQL 16 local, disco de 200 GB en BKP01 y BKP02 (`/srv/bareos`), TLS 1.3, Media Type `File` y `FileBKP02`. Ver `configs/linux/bareos/` 📸 |
| BKP-02 | Agentes en los Windows (FS con VSS, DC con estado del sistema) y en los Linux | ⏳ Parcial | 27/11: agentes en LNX01, LNX02 y BKP01 (FileSet `CiberNovaLinux` y `CiberNovaBKP01`). Faltan los Windows (y abrir 9103 en BKP01 para .23–.26) |
| BKP-03 | Copia de SQL Server desde la secundaria | ✅ | 27/11: `scripts/linux/bareos-sql-backup.sh` v1.2 (`ClientRunBeforeJob`): `COPY_ONLY` en la secundaria sincronizada (o en la principal si no hay ninguna), `cibernova_pruebas` y `cibernova_portal`, login `backup_cibernova` (`db_backupoperator`) 📸 |
| BKP-04 | Copy jobs BKP01 → BKP02 (3-2-1), programación y retenciones según RPO/RTO | ✅ | 27/11: pool `Copia-BKP02`, `Next Pool`, trabajo `copia-a-bkp02` (`PoolUncopiedJobs`); calendario `CiberNova-Sesiones` (Full martes 16:45, Incremental jueves 18:30), catálogo prioridad 11, copia prioridad 15. ❓ RPO de 2 a 5 días [PENDIENTE DE CONFIRMAR con Oriol] 📸 |
| BKP-05 | Director en *cold standby* en BKP02 + copia del catálogo | ✅ | 27/11 (opción A): Director y PostgreSQL instalados en BKP02, Director `disabled`; `scripts/linux/bareos-standby-sync.sh` v1.0 (cron cada 30 min en BKP01) envía `/etc/bareos` y `pg_dump` del catálogo a `/srv/bareos/standby`. ⏳ Prueba de activación y procedimiento en el manual (DOC-04) 📸 |

## 15. Pruebas y evidencias (obligatorias)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| PR-01 | **15 pruebas del Anexo I** (ap. 10) con captura cada una | ⏳ | Necesitan FS, GPO y clientes |
| PR-02 | Caída de AD/DNS: DC01 apagado, el cliente sigue | ⏳ | 📸 |
| PR-03 | Caída de ficheros: FS01 apagado, DFS sigue con FS02 | ⏳ | 📸 |
| PR-04 | Caída de BBDD/web/SFTP: LNX01 apagado, la VIP pasa a LNX02 | ⏳ Parcial | **BBDD ✅ (26/11):** `qm stop 128` con LNX01 principal → *fencing* (17:34:34), LNX02 principal, VIP en LNX02, ≈ 36 s sin servicio (36 de 189 pings perdidos), 0 datos perdidos, LNX01 vuelve sola como secundaria. **Web ✅ (26/11):** conmutación con la cadena completa (VIP → Apache → PHP → SQL Server) ≈ 29 s. **Falta SFTP** 📸 |
| PR-05 | Caída de DHCP: el nodo en espera responde | ⏳ | VM de prueba en `vmbr1` (VMID 199 propuesto [PENDIENTE DE CONFIRMAR]): recibir IP, apagar Kea en LNX01 y comprobar que LNX02 sigue dando IP 📸 |
| PR-06 | Restauración de copias (archivo, BBDD) y con BKP01 apagado | ✅ | 27/11: restauración con SHA-256 idénticos (trabajo 3) y de la BD (36 filas, id máx. 4002); con el almacenamiento de BKP01 parado, restauración desde BKP02 (trabajo 9: 2.225/2.225 ficheros, SHA-256 idénticos, `.bak` recuperado). Hallazgo: 9103 de BKP02 abierto a .28/.29 📸 |
| PR-07 | Movimientos de personal del Anexo I ap. 11 cuando lo indique el profesorado | ⏳ | |

## 16. Entregables y gestión

| ID | Entregable | Estado | Qué falta |
|---|---|---|---|
| DOC-01 | Documento de diseño (memoria, **diagramas**, justificación, plan de direccionamiento) | ⏳ Borrador v0.6 | Diagramas de red y arquitectura en `docs/diagramas`; cerrar propuestas de recursos y RPO/RTO |
| DOC-02 | Guía de instalación reproducible del hipervisor | ⏳ Borrador v0.4 | Comprobaciones del host, importación de OVA |
| DOC-03 | Memoria técnica de la infraestructura desplegada | ⏳ En curso | Cada servicio al terminarlo |
| DOC-04 | Manual de operación y plan de recuperación | ⏳ No empezado | Arranque/apagado, conmutaciones, restauración |
| DOC-05 | Inventario de servicios, usuarios y grupos (matriz de permisos, diagrama de OU y grupos, scripts, evidencias) | ⏳ Parcial | FS-05, FS-06, PR-01 |
| DOC-06 | Anexo de necesidades de IA | ⏳ No empezado | Métricas, tareas repetitivas, ideas para la Fase 2 |
| DOC-07 | Calendario inicial y seguimiento | ⏳ | Replanificar por el cierre del 4/12 (D-04) · ❓ ¿se entregó el calendario inicial al profesorado? |
| DOC-08 | Bitácora con todos los desfases | ⏳ Continuo | |
| DOC-09 | Repositorio Git: commits significativos con conventional commits | ⏳ Continuo | **Todo subido el 4/12**. GitHub va por la V20 (`6822190`, 24/11). Los 3 primeros commits salen con autor Claude (registrado en la bitácora 19/11); los nuevos, con autoría de Max u Oriol. Primeros ficheros reales de Linux en `configs/linux/` (V21). Carpetas `scripts/linux` y `docs/diagramas` vacías |
| DOC-10 | Memoria del proyecto (Google Doc → `docs/Proyecto-memoria.pdf`) | ⏳ | Regenerar el PDF con las capturas nuevas |
| DOC-11 | Defensa: 5-10 min, los dos participan, demo funcional | ⏳ | ❓ fecha de la defensa |

## 17. Preguntas para el profesorado

| ID | Pregunta | Afecta a |
|---|---|---|
| Q-01 | ~~¿Se permite un DHCP propio en la red del aula?~~ Resuelto: DHCP en la red aislada `vmbr1` (27/11) | DHCP-01 |
| Q-02 | ¿Se esperan VLAN en la Fase 1? | Diseño 3.11 |
| Q-03 | El rango .23–.33 tiene Internet (18/11) pero el DNS está interceptado: ¿puede tener DNS sin interceptar? ¿Hay un NTP recomendado? | LNX-07, AD-13, DNS-06 |
| Q-04 | Fecha de la defensa y si las sesiones del 10/12 y 15/12 sirven para la demo | DOC-11, calendario |
| Q-05 | Fin de la Fase 3 (caducidad de `auditor.ext`) | AD-14 |
| Q-06 | ¿Se puede cablear una segunda NIC del host? | HV-04 |
