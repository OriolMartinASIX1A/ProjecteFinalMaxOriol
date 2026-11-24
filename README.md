# CiberNova Solutions – Proyecto Intermodular 2026-2027

**Grupo 3:** Max (Linux) · Oriol (Windows)

Diseño, implantación, IA aplicada y auditoría de la infraestructura virtualizada y redundante de CiberNova Solutions.

## Estado

| Fase | Trimestre | Estado |
|---|---|---|
| 1 – Infraestructura | 1.º | En curso · **repositorio cerrado el 4/12/2026** · último día de trabajo 15/12/2026 |
| 2 – IA aplicada | 2.º | Pendiente |
| 3 – Seguridad y auditoría | 3.º | Pendiente |

**Versión:** V19 (24/11/2026) · historial en [`VERSION.md`](VERSION.md)

## Estructura del repositorio

```
.
├── docs/
│   ├── fase1/            Documentación de la Fase 1
│   │   ├── 01-documento-diseno.md
│   │   ├── 02-guia-instalacion-hipervisor.md
│   │   ├── 03-memoria-tecnica.md
│   │   ├── 05-inventario-servicios-usuarios-grupos.md
│   │   └── 07-guia-dominio-dc02-union.md
│   ├── gestion/          Lista de tareas, calendario, bitácora y desfases
│   │   ├── lista-tareas-fase1.md
│   │   ├── calendario-fase1.md
│   │   └── bitacora.md
│   └── diagramas/        Diagramas (Mermaid / draw.io)
├── scripts/
│   ├── windows/          PowerShell (altas, movimientos, GPO…)
│   └── linux/            Bash / Ansible
└── configs/
    ├── windows/          Exportaciones de configuración
    └── linux/            Ficheros de configuración versionados
```

## Entregables de la Fase 1

| Entregable | Fichero | Estado |
|---|---|---|
| Memoria del proyecto (exportada de Google Docs) | [`docs/Proyecto-memoria.pdf`](docs/Proyecto-memoria.pdf) | PDF del 16/11 (con capturas de Proxmox y DC01); regenerar con las capturas nuevas |
| Documento de diseño de la infraestructura | [`docs/fase1/01-documento-diseno.md`](docs/fase1/01-documento-diseno.md) | Borrador v0.6 (faltan diagramas de red y cerrar propuestas) |
| Guía de instalación reproducible del hipervisor | [`docs/fase1/02-guia-instalacion-hipervisor.md`](docs/fase1/02-guia-instalacion-hipervisor.md) | Borrador v0.4 |
| Memoria técnica de la infraestructura desplegada | [`docs/fase1/03-memoria-tecnica.md`](docs/fase1/03-memoria-tecnica.md) | En curso v0.7 (DC01, AD, DNS, GPO, scripts, LNX01, clones, SQL Server) |
| Manual de operación y plan de recuperación | `docs/fase1/04-manual-operacion.md` | Pendiente |
| Inventario de servicios, usuarios y grupos | [`docs/fase1/05-inventario-servicios-usuarios-grupos.md`](docs/fase1/05-inventario-servicios-usuarios-grupos.md) | Parcial v0.8 (falta matriz de permisos, grupos `DL_`, diagrama de grupos y evidencias) |
| Anexo de necesidades de IA | `docs/fase1/06-anexo-ia.md` | Pendiente |
| Guía del dominio: DNS y resto de DC01, DC02 y unión de todas las máquinas | [`docs/fase1/07-guia-dominio-dc02-union.md`](docs/fase1/07-guia-dominio-dc02-union.md) | v1.5 (19/11) · DC02 en VirtualBox y paso de los dos DC a Proxmox |
| **Lista de tareas** (todos los requisitos y su estado) | [`docs/gestion/lista-tareas-fase1.md`](docs/gestion/lista-tareas-fase1.md) | v1.3 (19/11) |
| Calendario | [`docs/gestion/calendario-fase1.md`](docs/gestion/calendario-fase1.md) | Replanificado 17/11 (cierre de GitHub, D-04) · revisado 19/11 |
| Bitácora y desfases | [`docs/gestion/bitacora.md`](docs/gestion/bitacora.md) | Al día (19/11) · desfases D-01 a D-05 |

## Scripts

| Script | Función |
|---|---|
| [`scripts/windows/01-crear-ou-grupos.ps1`](scripts/windows/01-crear-ou-grupos.ps1) | OU y grupos globales de AD |
| [`scripts/windows/02-alta-usuarios.ps1`](scripts/windows/02-alta-usuarios.ps1) | Políticas de contraseña, alta de los 89 empleados y de las 6 cuentas adm. |
| [`scripts/windows/03-cuentas-especiales.ps1`](scripts/windows/03-cuentas-especiales.ps1) | recepcion.bcn, auditor.ext y cuentas de servicio svc_* |
| [`scripts/windows/04-configurar-dns.ps1`](scripts/windows/04-configurar-dns.ps1) | DNS de DC01: actualizaciones seguras, sin transferencias, zona inversa, reenviadores, registros fijos y limpieza (alternativa reproducible a la configuración gráfica del 18/11) |
| [`scripts/windows/05-gpo.ps1`](scripts/windows/05-gpo.ps1) | GPO de seguridad: cuentas de servicio sin inicio de sesión, cuentas `adm.` fuera de los equipos de usuarios, firewall y auditoría avanzada |
| [`scripts/windows/84-deshacer-dns.ps1`](scripts/windows/84-deshacer-dns.ps1) | Deshace la configuración del script 04 (con copia de las zonas y confirmación); no toca lo que necesita el dominio. Ejecutado en DC01 tras el script 04; el DNS se rehízo por la interfaz gráfica el 18/11 |
| [`scripts/windows/90-comprobar-ou-grupos.ps1`](scripts/windows/90-comprobar-ou-grupos.ps1) | Solo lectura: árbol de OU, grupos con número de miembros y Admins. del dominio (para capturas) |
| [`scripts/windows/91-comprobar-usuarios.ps1`](scripts/windows/91-comprobar-usuarios.ps1) | Solo lectura: empleados por departamento, becarios y cuentas especiales (para capturas). `-Lista` abre la lista completa |
| [`scripts/windows/92-comprobar-cuentas-especiales.ps1`](scripts/windows/92-comprobar-cuentas-especiales.ps1) | Solo lectura: requisitos de las cuentas especiales (Anexo I, ap. 5) con OK / FALLO (para capturas) |
| [`scripts/windows/94-comprobar-gpo.ps1`](scripts/windows/94-comprobar-gpo.ps1) | Solo lectura: las 4 GPO del script 05 con OK / FALLO e informe HTML de cada una (para capturas) |
| [`scripts/windows/93-comprobar-dns.ps1`](scripts/windows/93-comprobar-dns.ps1) | Solo lectura: configuración y resolución DNS con OK / FALLO (también contra DC02 con `-Servidor`) |

> Script 04 v1.0 ejecutado en DC01 el 17/11. Scripts 04 y 93 v1.1 (18/11/2026): reenviadores en lugar del DNS del aula (la red del aula intercepta el DNS). Scripts 04 y 93 v1.2 (19/11/2026): reenviadores **8.8.8.8 y 1.1.1.1**, los configurados de verdad en DC01 (la v1.1 decía 1.1.1.1 y 9.9.9.9 por error de anotación).
>
> Script 01 v2.1, script 02 v2.2 y script 03 v1.0 (16/11/2026): corrigen los errores de la v1 (ver [memoria técnica, apartado 5.2](docs/fase1/03-memoria-tecnica.md#52-error-de-la-versión-1-y-corrección)). Probados con Active Directory simulado y **ejecutados con éxito en DC01 el 16/11/2026**.

## Normas del repositorio

- Documentación en Markdown; diagramas en Mermaid.
- Mensajes de commit con [Conventional Commits](https://www.conventionalcommits.org/es/): `feat:`, `fix:`, `docs:`, `chore:`…
- **Nunca** se suben contraseñas ni secretos (usar `.gitignore` y variables de entorno o un gestor de secretos).
