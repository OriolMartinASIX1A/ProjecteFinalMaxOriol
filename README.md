# CiberNova Solutions – Proyecto Intermodular 2026-2027

**Grupo 3:** Max (Linux) · Oriol (Windows)

Diseño, implantación, IA aplicada y auditoría de la infraestructura virtualizada y redundante de CiberNova Solutions.

## Estado

| Fase | Trimestre | Estado |
|---|---|---|
| 1 – Infraestructura | 1.º | En curso (entrega 15/12/2026) |
| 2 – IA aplicada | 2.º | Pendiente |
| 3 – Seguridad y auditoría | 3.º | Pendiente |

**Versión:** V11 (17/11/2026) · historial en [`VERSION.md`](VERSION.md)

## Estructura del repositorio

```
.
├── docs/
│   ├── fase1/            Documentación de la Fase 1
│   │   └── 01-documento-diseno.md
│   ├── gestion/          Calendario, bitácora y desfases
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
| Memoria del proyecto (exportada de Google Docs) | [`docs/Proyecto-memoria.pdf`](docs/Proyecto-memoria.pdf) | Al día (16/11), con capturas de Proxmox y DC01 |
| Documento de diseño de la infraestructura | [`docs/fase1/01-documento-diseno.md`](docs/fase1/01-documento-diseno.md) | Borrador v0.2 |
| Guía de instalación reproducible del hipervisor | [`docs/fase1/02-guia-instalacion-hipervisor.md`](docs/fase1/02-guia-instalacion-hipervisor.md) | Borrador v0.2 |
| Memoria técnica de la infraestructura desplegada | [`docs/fase1/03-memoria-tecnica.md`](docs/fase1/03-memoria-tecnica.md) | En curso (DC01, AD, scripts v2, LNX01) |
| Manual de operación y plan de recuperación | `docs/fase1/04-manual-operacion.md` | Pendiente |
| Inventario de servicios, usuarios y grupos | [`docs/fase1/05-inventario-servicios-usuarios-grupos.md`](docs/fase1/05-inventario-servicios-usuarios-grupos.md) | Parcial (falta matriz de permisos y evidencias) |
| Anexo de necesidades de IA | `docs/fase1/06-anexo-ia.md` | Pendiente |
| Calendario | [`docs/gestion/calendario-fase1.md`](docs/gestion/calendario-fase1.md) | Replanificado 16/11 |
| Bitácora y desfases | [`docs/gestion/bitacora.md`](docs/gestion/bitacora.md) | Al día (16/11) |

## Scripts

| Script | Función |
|---|---|
| [`scripts/windows/01-crear-ou-grupos.ps1`](scripts/windows/01-crear-ou-grupos.ps1) | OU y grupos globales de AD |
| [`scripts/windows/02-alta-usuarios.ps1`](scripts/windows/02-alta-usuarios.ps1) | Políticas de contraseña, alta de los 89 empleados y de las 6 cuentas adm. |
| [`scripts/windows/03-cuentas-especiales.ps1`](scripts/windows/03-cuentas-especiales.ps1) | recepcion.bcn, auditor.ext y cuentas de servicio svc_* |
| [`scripts/windows/90-comprobar-ou-grupos.ps1`](scripts/windows/90-comprobar-ou-grupos.ps1) | Solo lectura: árbol de OU, grupos con número de miembros y Admins. del dominio (para capturas) |
| [`scripts/windows/92-comprobar-cuentas-especiales.ps1`](scripts/windows/92-comprobar-cuentas-especiales.ps1) | Solo lectura: requisitos de las cuentas especiales (Anexo I, ap. 5) con OK / FALLO (para capturas) |
| [`scripts/windows/91-comprobar-usuarios.ps1`](scripts/windows/91-comprobar-usuarios.ps1) | Solo lectura: empleados por departamento, becarios y cuentas especiales (para capturas). `-Lista` abre la lista completa |

> Script 01 v2.1, script 02 v2.2 y script 03 v1.0 (16/11/2026): corrigen los errores de la v1 (ver [memoria técnica, apartado 5.2](docs/fase1/03-memoria-tecnica.md#52-error-de-la-versión-1-y-corrección)). Probados con Active Directory simulado y **ejecutados con éxito en DC01 el 16/11/2026**.

## Normas del repositorio

- Documentación en Markdown; diagramas en Mermaid.
- Mensajes de commit con [Conventional Commits](https://www.conventionalcommits.org/es/): `feat:`, `fix:`, `docs:`, `chore:`…
- **Nunca** se suben contraseñas ni secretos (usar `.gitignore` y variables de entorno o un gestor de secretos).
