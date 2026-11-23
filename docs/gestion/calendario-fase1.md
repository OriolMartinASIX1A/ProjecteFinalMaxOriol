# Calendario – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Elaborado:** 13/11/2026 · **Replanificado:** 17/11/2026, tarde (desfases D-01 a D-05, ver [bitácora](bitacora.md)) · **Revisado:** 19/11/2026 · **Propuesta pendiente de confirmar por Max y Oriol**
**⚠️ Cierre del repositorio de GitHub: viernes 4/12/2026** (después no se puede subir ni cambiar nada) · **Último día de trabajo:** martes 15/12/2026 · **Defensa:** fecha pendiente de comunicar por el profesorado
**Lista completa de tareas:** [`lista-tareas-fase1.md`](lista-tareas-fase1.md)

## Tiempo disponible

| Día | Horario |
|---|---|
| Martes | 15:00 – 17:00 |
| Jueves | 17:00 – 19:00 |

Del 17/11 al 3/12 hay **6 sesiones de 2 h = 12 h de laboratorio** antes del cierre de GitHub. Las sesiones del 10/12 y del 15/12 quedan después del cierre: lo que se haga en ellas no puede entrar en el repositorio [PENDIENTE DE CONFIRMAR si sirven para la demo y la defensa]. El martes 8/12 es festivo en el centro.

Los servidores solo pueden estar encendidos en horario de proyecto. Las VMs se construyen en **VirtualBox fuera de horario** y en las sesiones se **importan en Proxmox** y se prueban (D-01).

## Estado de partida (16/11)

| Ya hecho | Pendiente de confirmar |
|---|---|
| Proxmox instalado y actualizado | Máscara /22, `lsblk`, `ip -br link`, `pveversion` |
| DC01 con el bosque `cibernova.local` (en VirtualBox, sin importar) | — |
| OU y grupos globales | El script de usuarios v1 dio error: corregido (v2), falta ejecutarlo en DC01 |
| DC02 sin montar | Crear con instalación limpia (no clon de DC01) |
| VMs Ubuntu creadas en Proxmox. **17/11:** WEB01 descartada (no era 24.04); LNX01 instalada de cero en VirtualBox y exportada a OVA (D-03) | Versión de Ubuntu de LNX02, BKP01 y BKP02 (debe ser 24.04) |

## Planificación por sesión (replanificada el 17/11 por D-04 y D-05)

> Todo lo que va en la entrega tiene que estar **subido a GitHub el viernes 4/12**. Por eso los servicios y **todas las pruebas** (15 del Anexo I, caídas y restauración) pasan a las sesiones 2–6.

| # | Fecha | Oriol (Windows) | Max (Linux) | Hito |
|---|---|---|---|---|
| 1 | Mar 17/11 | ~~Exportar e importar DC01~~ (no hecho, D-05) | **Hecho:** comprobaciones del host, VMs antiguas borradas, LNX01 importada (VMID 128), netplan y DNS, SQL Server 2025 instalado (sin configurar), LNX02 (.29) clonada y personalizada, BKP01 clonada | **H2** (parcial) |
| 2 | Jue 19/11 | **DC02 en VirtualBox** (decisión del 19/11, confirmada con Oriol): instalación limpia junto a DC01 (adaptador puente), promoción y comprobación de la replicación. Después, exportar **los dos DC** a OVA e importarlos en Proxmox (DC01 primero) en cuanto la replicación esté bien (guía 07, apartado 2) | **Hecho:** BKP01 personalizada (18/11, fuera de horario). `mssql-conf setup` en LNX01/LNX02 (Enterprise Developer) y BKP01 (Express), Always On activado (Agente en LNX01/LNX02). **BKP02** (131, .31) clonada de la instantánea `base-limpia` (sin SQL Server) y personalizada. Las cuatro Linux actualizadas al mismo kernel | **H2** + **H3** (1/3) |
| 3 | Mar 24/11 | Replicación DC01–DC02. Importar FS01/FS02, DFS-N + DFS-R, carpetas, grupos `DL_` | ~~Pacemaker + Corosync, `fence_pve`~~ (**adelantado al 23/11**, clúster de 3 nodos sin qdevice). Empezar el **AG de SQL Server** (sesión 4) | **H3** (2/3) |
| 4 | Jue 26/11 | Permisos NTFS (P-01–P-44), ABE, FSRM, auditoría. GPO y unir clientes | AG de SQL Server + réplica config-only + VIP .27. Apache + PHP-FPM + `sqlsrv` + web | **H3** (3/3) |
| 5 | Mar 1/12 | GPO de las cuentas especiales. Agentes de Bareos en Windows y `svc_backup` (con Max) | SFTP con chroot, Kea HA, Bareos en BKP01/BKP02. **Punto de control del AG** | **H4** Redundancia |
| 6 | Jue 3/12 | **15 pruebas del Anexo I** con capturas | **Pruebas de caída** de cada servicio y **prueba de restauración** con capturas | **H5** Pruebas |
| — | Lun 23/11 | — | **Fuera de horario:** clúster Pacemaker `cibernova-g3` de 3 nodos (LNX01, LNX02, BKP01) con quórum, usuario `fence@pve` con mínimo privilegio, STONITH `fence_pve` y prueba real de fencing de LNX02 | Adelanto |
| — | Jue 19/11 (tarde) | **DC02 en VirtualBox:** instalado, promovido y replicando con DC01 (0 errores); DNS de DC02 completo (reenviadores 8.8.8.8 / 1.1.1.1, sin reenvío entre DC); hora, GPO y FSMO comprobados. Falta exportar e importar los dos DC | — | Hecho |
| — | Mié 18/11 | **Fuera de horario (DC01 en VirtualBox):** DNS completado y verificado (reenviadores 8.8.8.8 y 1.1.1.1 por la intercepción DNS del aula), hora con `hora.roa.es`, 4 GPO de seguridad (script 05) | — | Adelanto |
| — | **Vie 4/12** | **Fuera de horario: última revisión y subida a GitHub (cierre)** | | **Entrega** |
| — | Mar 8/12 | *Festivo* | *Festivo* | — |
| 7 | Jue 10/12 | Ensayo de la defensa (sin cambios en el repositorio) | Ensayo de la defensa | — |
| 8 | Mar 15/12 | Defensa / margen (sin cambios en el repositorio) | Defensa / margen | — |

**Riesgo anotado el 19/11:** las sesiones 3–5 concentran casi todo el trabajo Linux. Propuesta [PENDIENTE DE CONFIRMAR]: preparar en casa los ficheros de configuración (Pacemaker, Apache, SFTP, Kea, Bareos) y versionarlos en `configs/linux/`, para que en la sesión solo se apliquen y se prueben; y adelantar a la semana del 19–26/11 los diagramas y el anexo de IA, que no necesitan las máquinas.

Con este calendario no queda margen para imprevistos antes del 4/12: si algo se retrasa, se decide qué se entrega con conmutación manual o documentado como pendiente (plan B), en vez de mover las pruebas.

Los identificadores de cada tarea (AD-11, FS-05…) están en la [lista de tareas](lista-tareas-fase1.md).

## Trabajo fuera de horario

| Semana | Oriol | Max | Ambos |
|---|---|---|---|
| 16–19/11 | Instalar DC02 limpio en VirtualBox **en el mismo equipo que DC01** y promocionarlo allí (cambio del 19/11: antes se iba a promover en Proxmox). Exportar los dos DC a OVA. FS01/FS02 en VirtualBox | ~~Crear LNX02 y BKP01 en VirtualBox~~ (hecho con clones en Proxmox el 17/11). Preparar las configuraciones de Pacemaker y del AG | Revisar las propuestas del diseño (recursos de las VMs, RPO/RTO, OU Equipos/Servidores) |
| 20–26/11 | Matriz de permisos P-01 a P-44; scripts de carpetas y permisos, de carpetas personales (script 02 nueva versión) y de movimientos de personal | Ficheros de configuración de Pacemaker, AG, Apache, SFTP y Kea | Bitácora; decidir la aplicación web |
| 27/11–3/12 | GPO de perfiles, redirección y unidades (las de seguridad ya están, 18/11) | Configuración de Bareos (jobs, pools, retenciones) | Memoria técnica |
| 27/11–3/12 (adelantado por D-04) | Inventario de servicios, usuarios y grupos | Manual de operación y plan de recuperación | Anexo de necesidades de IA; memoria técnica completa |
| 4/12 | — | — | **Revisión final y subida a GitHub** |
| 5–15/12 | — | — | Presentación de la defensa |

## Puntos de control y planes B

| Fecha | Comprobación | Si no se cumple |
|---|---|---|
| Mar 17/11 | DC01 importado y funcionando en Proxmox | **No cumplido (D-05).** Se importa al empezar la sesión 2 |
| Jue 19/11 | Los dos DC replican (en VirtualBox, antes de exportar) — **✅ cumplido** | Usar el margen de Windows en la sesión 3 |
| Mar 1/12 | El AG conmuta automáticamente | Plan B: AG con conmutación manual (documentado como desfase); el resto de servicios no se retrasa |
| Mar 1/12 | Copias funcionando en BKP01 y BKP02 | Dejar solo BKP01 y documentar la copia secundaria como pendiente |
| Jue 3/12 | 15 pruebas del Anexo I superadas y capturas hechas | Documentar las fallidas como pendientes y subir el 4/12 (no hay sesiones con repositorio abierto después) |
| Vie 4/12 | Todo subido a GitHub | Sin plan B: después del cierre no se puede subir nada |

Los cambios respecto a este calendario se registran en la [bitácora](bitacora.md).
