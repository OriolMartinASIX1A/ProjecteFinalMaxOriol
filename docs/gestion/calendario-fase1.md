# Calendario – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Elaborado:** 13/11/2026 · **Replanificado:** 17/11/2026, tarde (desfases D-01 a D-05, ver [bitácora](bitacora.md)) · **Propuesta pendiente de confirmar por Max y Oriol**
**⚠️ Cierre del repositorio de GitHub: viernes 4/12/2026** (después no se puede subir ni cambiar nada) · **Último día de trabajo:** martes 15/12/2026 · **Defensa:** fecha pendiente de comunicar por el profesorado

## Tiempo disponible

| Día | Horario |
|---|---|
| Martes | 15:00 – 17:00 |
| Jueves | 17:00 – 19:00 |

Del 17/11 al 15/12 hay **8 sesiones de 2 h = 16 h de laboratorio**. El martes 8/12 es festivo en el centro.

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
| 2 | Jue 19/11 | **Importar DC01** (método manual si el asistente falla) y comprobar dominio y DNS. Importar DC02 (instalación limpia hecha en casa) y promoverlo | Personalizar **BKP01** (.30, clonada el 17/11). `mssql-conf setup` en LNX01/LNX02 (Enterprise Developer) y BKP01 (Express), Always On activado. Crear **BKP02** (clon sin SQL Server) | **H2** + **H3** (1/3) |
| 3 | Mar 24/11 | Replicación DC01–DC02. Importar FS01/FS02, DFS-N + DFS-R, carpetas, grupos `DL_` | Pacemaker + Corosync (`cibernova-g3`), qdevice en BKP01, `fence_pve` | **H3** (2/3) |
| 4 | Jue 26/11 | Permisos NTFS (P-01–P-44), ABE, FSRM, auditoría. GPO y unir clientes | AG de SQL Server + réplica config-only + VIP .27. Apache + PHP-FPM + `sqlsrv` + web | **H3** (3/3) |
| 5 | Mar 1/12 | GPO de las cuentas especiales. Agentes de Bareos en Windows y `svc_backup` (con Max) | SFTP con chroot, Kea HA, Bareos en BKP01/BKP02. **Punto de control del AG** | **H4** Redundancia |
| 6 | Jue 3/12 | **15 pruebas del Anexo I** con capturas | **Pruebas de caída** de cada servicio y **prueba de restauración** con capturas | **H5** Pruebas |
| — | **Vie 4/12** | **Fuera de horario: última revisión y subida a GitHub (cierre)** | | **Entrega** |
| — | Mar 8/12 | *Festivo* | *Festivo* | — |
| 7 | Jue 10/12 | Ensayo de la defensa (sin cambios en el repositorio) | Ensayo de la defensa | — |
| 8 | Mar 15/12 | Defensa / margen (sin cambios en el repositorio) | Defensa / margen | — |

Con este calendario no queda margen para imprevistos antes del 4/12: si algo se retrasa, se decide qué se entrega con conmutación manual o documentado como pendiente (plan B), en vez de mover las pruebas.

## Trabajo fuera de horario

| Semana | Oriol | Max | Ambos |
|---|---|---|---|
| 16–19/11 | Exportar DC01 a OVA (antes del jueves). Instalar DC02 limpio (sin promover) y FS01/FS02 en VirtualBox | ~~Crear LNX02 y BKP01 en VirtualBox~~ (hecho con clones en Proxmox el 17/11). Preparar las configuraciones de Pacemaker y del AG | Revisar las propuestas del diseño (recursos de las VMs, RPO/RTO, OU Equipos/Servidores) |
| 20–26/11 | Matriz de permisos P-01 a P-44 | Ficheros de configuración de Apache, SFTP y Kea | Bitácora |
| 27/11–3/12 | Diseño de las GPO | Configuración de Bareos (jobs, pools, retenciones) | Memoria técnica |
| 27/11–3/12 (adelantado por D-04) | Inventario de servicios, usuarios y grupos | Manual de operación y plan de recuperación | Anexo de necesidades de IA; memoria técnica completa |
| 4/12 | — | — | **Revisión final y subida a GitHub** |
| 5–15/12 | — | — | Presentación de la defensa |

## Puntos de control y planes B

| Fecha | Comprobación | Si no se cumple |
|---|---|---|
| Mar 17/11 | DC01 importado y funcionando en Proxmox | **No cumplido (D-05).** Se importa al empezar la sesión 2 |
| Jue 19/11 | Los dos DC replican | Usar el margen de Windows en la sesión 3 |
| Mar 1/12 | El AG conmuta automáticamente | Plan B: AG con conmutación manual (documentado como desfase); el resto de servicios no se retrasa |
| Mar 1/12 | Copias funcionando en BKP01 y BKP02 | Dejar solo BKP01 y documentar la copia secundaria como pendiente |
| Jue 3/12 | 15 pruebas del Anexo I superadas y capturas hechas | Documentar las fallidas como pendientes y subir el 4/12 (no hay sesiones con repositorio abierto después) |
| Vie 4/12 | Todo subido a GitHub | Sin plan B: después del cierre no se puede subir nada |

Los cambios respecto a este calendario se registran en la [bitácora](bitacora.md).
