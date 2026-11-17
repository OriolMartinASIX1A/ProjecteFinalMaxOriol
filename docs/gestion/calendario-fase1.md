# Calendario – Fase 1

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Elaborado:** 13/11/2026 · **Replanificado:** 17/11/2026 (desfases D-01, D-02 y D-03, ver [bitácora](bitacora.md))
**Último día de trabajo:** martes 15/12/2026 · **Defensa:** fecha pendiente de comunicar por el profesorado

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

## Planificación por sesión (replanificada)

| # | Fecha | Oriol (Windows) | Max (Linux) | Hito |
|---|---|---|---|---|
| 1 | Mar 17/11 | Preguntar al profesorado por el DHCP propio y las VLAN (con Max). Comprobaciones del host (con Max). Ejecutar el script 01 v2.1 (OU Equipos y Servidores) si falta. **Exportar DC01 a OVA** (no se pudo el 16/11: servidor apagado) e **importarlo** en Proxmox y comprobar red, DNS, dominio y rendimiento (`pveperf`) | Comprobaciones del host. **Importar `LNX01.ova`** (VirtIO), apagar WEB01 y poner la IP .28 con netplan. Comprobar versión, nombre e IP de LNX02, BKP01 y BKP02 | **H2** Hipervisor y primeras VMs |
| 2 | Jue 19/11 | Importar DC02 (instalación limpia hecha en casa), promoverlo y comprobar replicación. Reenviadores DNS. OU Equipos/Servidores (si se aprueban) | Instalar SQL Server 2025 en LNX01/02 y Express en BKP01 | **H3** Servicios core (1/3) |
| 3 | Mar 24/11 | Importar FS01/FS02. DFS-N + DFS-R, estructura de carpetas, grupos `DL_` | Pacemaker + Corosync (`cibernova-g3`), qdevice en BKP01, fencing `fence_pve` | **H3** (2/3) |
| 4 | Jue 26/11 | Permisos NTFS (matriz P-01–P-44), ABE, FSRM (cuotas), auditoría de acceso | AG de SQL Server + réplica config-only + recurso en Pacemaker + VIP .27 | **H3** (3/3) |
| 5 | Mar 1/12 | GPO: perfiles, redirección, unidades de red, restricciones de las cuentas especiales (script 03 ya preparado el 16/11). Unir clientes | Apache + PHP-FPM + `sqlsrv` + web; SFTP con chroot; Apache en Pacemaker. **Punto de control del AG** | **H4** Redundancia (1/2) |
| 6 | Jue 3/12 | Agentes de Bareos en Windows y `svc_backup` (con Max). Script de movimientos de personal | Kea HA + reservas. Bareos en BKP01/BKP02 | **H4** (2/2) |
| — | Mar 8/12 | *Festivo* | *Festivo* | — |
| 7 | Jue 10/12 | 15 pruebas del Anexo I (capturas). Movimientos de personal | Pruebas de caída de cada servicio. Prueba de restauración. Capturas | **H5** Pruebas y evidencias |
| 8 | Mar 15/12 | Margen para imprevistos · ensayo de la demo · entrega | Margen para imprevistos · ensayo de la demo · entrega | **H5** Entrega |

Gracias al adelanto de Windows (D-02), Oriol tiene margen para **ayudar a Max** si el AG de SQL Server se complica.

## Trabajo fuera de horario

| Semana | Oriol | Max | Ambos |
|---|---|---|---|
| 16–19/11 | Ejecutar los scripts v2 en DC01 (VirtualBox) y hacer capturas. Exportar DC01 a OVA. Instalar DC02 limpio (sin promover) y FS01/FS02 en VirtualBox | Decidir cómo trabajar en casa con las Ubuntu (propuesta: configuración en Git, ver memoria técnica 2.5). Configuraciones de Pacemaker y del AG | Revisar las propuestas del diseño (recursos de las VMs, RPO/RTO, OU Equipos/Servidores) |
| 20–26/11 | Matriz de permisos P-01 a P-44 | Ficheros de configuración de Apache, SFTP y Kea | Bitácora |
| 27/11–3/12 | Diseño de las GPO | Configuración de Bareos (jobs, pools, retenciones) | Memoria técnica |
| 4–10/12 | Inventario de servicios, usuarios y grupos | Manual de operación y plan de recuperación | Anexo de necesidades de IA |
| 11–15/12 | — | — | Presentación de la defensa |

## Puntos de control y planes B

| Fecha | Comprobación | Si no se cumple |
|---|---|---|
| Mar 17/11 | DC01 importado y funcionando en Proxmox | Seguir con DC01 en VirtualBox para preparar, y probar a instalar Windows directamente en Proxmox con los drivers VirtIO |
| Jue 19/11 | Los dos DC replican | Usar el margen de Windows en la sesión 3 |
| Mar 1/12 | El AG conmuta automáticamente | Plan B: AG con conmutación manual (documentado como desfase); el resto de servicios no se retrasa |
| Jue 3/12 | Copias funcionando en BKP01 y BKP02 | Dejar solo BKP01 y documentar la copia secundaria como pendiente |
| Jue 10/12 | 15 pruebas del Anexo I superadas | Repetir las fallidas en la sesión 8 |

Los cambios respecto a este calendario se registran en la [bitácora](bitacora.md).
