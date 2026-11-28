# Inventario de servicios, usuarios y grupos – Fase 1

**Grupo 3:** Max · Oriol
**Versión:** 0.17 (parcial) · 27/11/2026, noche (Max: Portal CiberNova, `backup_cibernova`, Bareos, Kea HA en `vmbr1`, SFTP) · **V22 definitiva (fusión del 28/11)** · v0.16 (parcial) · 27/11/2026 (Oriol, 26/11: 63 grupos `DL_` y matriz de permisos, carpetas personales, cuotas, perfiles, GPO de usuario y scripts 06, 07 y 96; OVA de los Windows exportadas el 27/11) · v0.15 · 27/11/2026 (sesión 4 Linux: base de datos en el AG, Apache + PHP-FPM en Pacemaker, `web_cibernova`, `ufw`) · v0.14 · 24/11/2026 (FS02 y DFS-R) · v0.13 · 24/11/2026 (AG `sqlag_cibernova` y VIP .27 en Pacemaker) · v0.12 · 23/11/2026 (FS01 en VirtualBox: dominio, roles, espacio de nombres y recursos compartidos) · v0.11 · 23/11/2026 (clúster Pacemaker `cibernova-g3` de 3 nodos con fencing) · v0.10 · 19/11/2026 (SQL Server configurado; BKP01 y BKP02 creadas) · v0.9 · 19/11/2026 (DC02 promovido y replicando) · v0.8 · 19/11/2026 (estado de AD/DNS y DC02) · v0.7 · 18/11/2026 (DNS y GPO de DC01)

> Entregable obligatorio de la Fase 1 (Anexo I, apartado 12). Esta versión recoge lo que ya está creado en el dominio. La matriz de permisos P-01 a P-44 y los 63 grupos `DL_` están en [`08-matriz-permisos.md`](08-matriz-permisos.md). Faltan el diagrama de anidamiento y las evidencias de las pruebas.

---

## 1. Inventario de servicios

| Servicio | Servidor(es) | IP | Estado |
|---|---|---|---|
| Virtualización | Proxmox VE | 192.168.202.3 | Funcionando |
| AD DS + DNS | DC01 / DC02 | .23 / .24 | DC01 y DC02 importados en Proxmox el 27/11 (123 y 124, parados; falta arrancarlos y volver a poner la IP). DNS configurado y verificado (18/11; reenviadores 8.8.8.8 y 1.1.1.1) y GPO de seguridad (18/11) · **DC02 promovido el 19/11 en VirtualBox** (DNS + catálogo global), replicando con DC01; reenviadores 8.8.8.8 y 1.1.1.1 y DNS cruzado. **OVA de los dos DC exportadas el 27/11**; pendiente: importarlas en Proxmox |
| Ficheros (DFS, FSRM) | FS01 / FS02 | .25 / .26 | **Importadas en Proxmox el 27/11** (125 y 126, paradas; falta arrancarlas y comprobar DFS-R). **FS01 en VirtualBox (23/11):** unida al dominio (OU Servidores), D: `Datos` de 150 GB, roles DFS-N, DFS-R y FSRM, espacio de nombres `\\cibernova.local\empresa` (modo 2008, ABE) y recursos `Personales$`, `Departamentos$`, `Proyectos$`, `Comun$` (ABE; *Usuarios autentificados* en el recurso, permisos reales en NTFS). **FS02 en VirtualBox (24/11):** unida al dominio, mismos recursos compartidos, segundo servidor del espacio de nombres y **DFS-R con FS01** (cuatro grupos, prueba OK). **26/11:** FS01 con prioridad (`GlobalLow`), 50 carpetas con los permisos de la matriz (script 06; 96: 0 errores en FS01 y FS02), 89 carpetas personales y cuotas en los dos servidores (script 07), carpeta DFS `Perfiles`. **OVA exportadas el 27/11**; pendiente: importarlas en Proxmox |
| Web + SFTP + SQL Server (VIP) | LNX01 / LNX02 | .27 (VIP) · .28 / .29 | LNX01 (VMID 128, .28) y LNX02 (VMID 129, .29) en Proxmox con SQL Server 2025 **Enterprise Developer** configurado, Always On y Agente activados (19/11). **Clúster Pacemaker `cibernova-g3`** de 3 nodos (LNX01, LNX02, BKP01) con fencing `fence_pve` probado (23/11). **AG `sqlag_cibernova`** (LNX01 principal, LNX02 secundaria síncrona, BKP01 solo configuración) gestionado por Pacemaker y **VIP .27** junto a la principal (24/11). **26/11:** base de datos de prueba `cibernova_pruebas` en el AG, conmutación manual y caída de LNX01 probadas (≈ 36 s, 0 datos perdidos); **Apache 2.4 + PHP-FPM 8.3** con `sqlsrv`/`pdo_sqlsrv` en los dos nodos y recurso `apache` de Pacemaker con la VIP; página `bbdd.php` con el login `web_cibernova`; `ufw` en LNX01 (LNX02 pendiente). Falta: aplicación web definitiva y SFTP |
| DHCP (Kea) | LNX01 / LNX02 | 10.10.10.28 / .29 (`ens19`, red aislada `vmbr1`) | **27/11:** Kea 2.4.1 en alta disponibilidad hot-standby (LNX01 primario), *pool* 10.10.10.100–200, solo en la red aislada. Falta la prueba de caída con la VM de prueba |
| Copias (Bareos) | BKP01 / BKP02 | .30 / .31 | **27/11:** Bareos 25.1.3. BKP01: Director, catálogo PostgreSQL 16 y almacenamiento (200 GB); BKP02: almacenamiento (200 GB, copias `Copia-BKP02`) y **Director en espera** (parado, configuración y catálogo sincronizados cada 30 min). Copias de LNX01, LNX02 (con las BD del AG) y BKP01; martes 16:45 (Full) y jueves 18:30 (Incremental). BKP01 sigue siendo la réplica de solo configuración del AG |

Todas las máquinas se unen al dominio `cibernova.local` (decidido el 17/11/2026, [guía 07](07-guia-dominio-dc02-union.md)). Estado detallado de cada servicio: [lista de tareas](../gestion/lista-tareas-fase1.md).

---

## 2. Estructura de OU

```
cibernova.local
└── CiberNova
    ├── Usuarios
    │   ├── Direccion · Administracion · RRHH · Comercial · Marketing
    │   └── Consultoria · Desarrollo · Sistemas · Soporte · Legal
    ├── Grupos
    ├── Cuentas especiales
    │   ├── Administracion
    │   └── Servicios
    ├── Equipos
    │   ├── Barcelona · Madrid · Valencia
    │   └── Recepcion
    ├── Servidores
    └── Bajas
```

**Justificación:**
- **Una OU por departamento** dentro de Usuarios, para poder aplicar GPO distintas por departamento (perfil móvil en Dirección y Comercial, redirección de carpetas en el resto).
- **La sede no es una OU** sino un atributo (`physicalDeliveryOfficeName`) y un grupo (`G_Sede_*`), porque Comercial, Consultoría, Desarrollo y Soporte tienen personal en varias sedes; una OU por sede obligaría a duplicar las GPO de departamento.
- **Cuentas especiales separadas** de los empleados: las cuentas adm. y de servicio no deben recibir las GPO de usuario (perfiles, unidades, redirección).
- **Bajas:** las cuentas que causan baja se deshabilitan y se mueven aquí, nunca se borran de inmediato (Anexo I, apartado 6).
- **Equipos y Servidores** (decidido 16/11/2026, script 01 v2.1): el contenedor por defecto `Computers` no admite GPO; estas OU permiten aplicar GPO de equipo (recepción, perfiles, unidades de red). Los controladores de dominio se quedan en `Domain Controllers`. Total: 23 OU bajo CiberNova.

---

## 3. Grupos globales (personas)

Miembros esperados según `usuarios_cibernova.csv` y la lógica del script (comprobados en la prueba simulada y **confirmados en DC01** el 16/11/2026 con `90-comprobar-ou-grupos.ps1`: 27 grupos y los mismos miembros).

### 3.1 Departamento

| Grupo | Miembros | Nota |
|---|---|---|
| G_Direccion | 4 | |
| G_Administracion | 7 | |
| G_RRHH | 5 | |
| G_Comercial | 12 | |
| G_Marketing | 5 | Sin la becaria (aitana.sempere) |
| G_Consultoria | 20 | |
| G_Desarrollo | 14 | Sin los 2 becarios (nerea.ruiz, kevin.lopez) |
| G_Sistemas | 6 | Cuentas personales (estándar, sin privilegios de administración) |
| G_Soporte | 8 | Sin el becario (izan.moreno) |
| G_Legal | 4 | |

### 3.2 Sede

| Grupo | Miembros |
|---|---|
| G_Sede_Barcelona | 65 |
| G_Sede_Madrid | 13 |
| G_Sede_Valencia | 11 |

### 3.3 Transversales

| Grupo | Miembros | Quiénes |
|---|---|---|
| G_Responsables | 10 | marta.vidal, rosa.martinez, begona.munoz, raul.fernandez, clara.gimenez, francisco.morales, david.garcia, miguel.torres, jorge.prieto, isabel.montoya |
| G_Proyecto_Sanitario | 7 | francisco.morales, monica.gallego, daniel.carrasco, sara.hidalgo, carlos.sanchez, david.garciam, natalia.serrano |
| G_Proyecto_Financiero | 6 | daniel.carrasco, albert.casals, alejandro.diaz, beatriz.rojas, hector.mira, lorena.peris |
| G_Comite_Seguridad | 4 | elena.castro, miguel.torres, isabel.montoya, roberto.vallejo |
| G_RRHH_Nominas | 2 | begona.munoz, tomas.rubio |

### 3.4 Becarios

| Grupo | Miembros | Quiénes |
|---|---|---|
| G_Becarios | 4 | nerea.ruiz, kevin.lopez, aitana.sempere, izan.moreno |
| G_Becarios_Desarrollo | 2 | nerea.ruiz, kevin.lopez |
| G_Becarios_Marketing | 1 | aitana.sempere |
| G_Becarios_Soporte | 1 | izan.moreno |

**Justificación (requisito del Anexo I, apartado 4):** los becarios **no** son miembros del grupo de su departamento, así que no heredan sus permisos. Tienen un grupo propio por departamento (`G_Becarios_<Depto>`) al que se le darán solo los permisos reducidos de P-17, P-21 y P-31. Se descartó añadirlos al grupo del departamento y poner un "denegar" encima porque las denegaciones prevalecen sobre cualquier permiso concedido y acaban bloqueando accesos que sí deberían tener (por ejemplo, Comunicados o Base_Conocimiento). `G_Becarios` agrupa a todos para las restricciones comunes (horario, caducidad, cuota, y que nunca accedan a Proyectos aunque se les añada por error a un grupo de proyecto, P-38).

### 3.5 Grupos de política

| Grupo | Miembros | Uso |
|---|---|---|
| G_Politica_15 | 16 | 4 de Dirección + 6 de Sistemas + 6 cuentas adm. Sujeto a la PSO de 15 caracteres |
| G_Admin_Sistemas | 6 | Las cuentas adm.*. Es miembro de **Admins. del dominio** (script v2): solo las cuentas adm. tienen privilegios de administración |

### 3.6 Grupos de cuentas especiales (script 03)

| Grupo | Miembros | Uso |
|---|---|---|
| G_Recepcion | 1 (recepcion.bcn) | Recibirá la consulta de Comun (excepto Intercambio) |
| G_Auditor_Externo | 1 (auditor.ext) | Recibirá la consulta de Sistemas\Documentacion y Legal\Comite_Seguridad |
| G_Cuentas_Servicio | 4 (svc_*) | Se le denegará el inicio de sesión interactivo por GPO |

---

## 4. Grupos de dominio local (permisos)

**Creados el 26/11/2026** con [`06-carpetas-permisos.ps1`](../../scripts/windows/06-carpetas-permisos.ps1) (v1.3) en `OU=Grupos,OU=CiberNova`, modelo **AGDLP** (`DL_<Carpeta>_<Nivel>`): **63 grupos `DL_`** de dominio local, con los grupos globales `G_` dentro. La lista completa (nivel, miembros, carpeta y requisitos) y la matriz P-01 a P-44 están en [`08-matriz-permisos.md`](08-matriz-permisos.md), apartados 4 y 5. Comprobados con `96-comprobar-carpetas-permisos.ps1` (v1.2): 0 errores en FS01 y FS02.

**Grupo global nuevo:** `G_RRHH_Nominas_Consulta` (rosa.martinez), para dar a la responsable de Administración consulta de `RRHH\Nominas` (P-08) sin poner permisos a un usuario.

**Grupos de las GPO de usuario (26/11):**

| GPO | Se aplica a | Qué hace |
|---|---|---|
| `GPO_Usuarios_Unidades` | Todos los usuarios de la OU CiberNova, con destino por grupo en cada unidad | G: (`G_Sede_*`), P: (`DL_Proyectos_L`), S: (`DL_Comun_C`) |
| `GPO_Usuarios_Redireccion` | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia`; denegada a `G_Direccion` y `G_Comercial` | Documentos y Escritorio a `Personales\%USERNAME%` |

---

## 5. Políticas de cuentas (aplicadas por script)

| Ámbito | Configuración | Cómo |
|---|---|---|
| General | Mínimo 12 caracteres, complejidad, historial 10, caducidad 90 días, bloqueo 15 min tras 5 intentos | `Set-ADDefaultDomainPasswordPolicy` |
| Dirección, Sistemas y cuentas adm. | Mínimo 15 caracteres (resto igual) | PSO `PSO_CiberNova_15` (precedencia 1) aplicada a `G_Politica_15` |
| Becarios | Inicio de sesión L-V 8:00-15:00; cuenta caduca el 30/06/2027 | Atributos `logonHours` y `accountExpires` por script |
| Todos | Cambio de contraseña obligatorio en el primer inicio de sesión | `-ChangePasswordAtLogon $true` |

---

## 6. Cuentas especiales

| Cuenta | Tipo | Estado | OU |
|---|---|---|---|
| adm.miguel.torres | Administración | Creada | Cuentas especiales\Administracion |
| adm.laia.ribas | Administración | Creada | Cuentas especiales\Administracion |
| adm.fernando.lara | Administración | Creada | Cuentas especiales\Administracion |
| adm.angel.ibanez | Administración | Creada | Cuentas especiales\Administracion |
| adm.sofia.bermudez | Administración | Creada | Cuentas especiales\Administracion |
| adm.inaki.arrieta | Administración | Creada | Cuentas especiales\Administracion |
| recepcion.bcn | Compartida | Script 03 | Cuentas especiales |
| auditor.ext | Externa temporal | Script 03 (**deshabilitada**) | Cuentas especiales |
| svc_backup | Servicio | Script 03 | Cuentas especiales\Servicios |
| svc_web | Servicio | Script 03 | Cuentas especiales\Servicios |
| svc_bbdd | Servicio | Script 03 | Cuentas especiales\Servicios |
| svc_ia | Servicio (Fase 2) | Script 03 | Cuentas especiales\Servicios |

Las cuentas adm. las crea el script 02 y las demás el script 03; los dos se ejecutaron en DC01 el 16/11/2026 (`92-comprobar-cuentas-especiales.ps1`: 26 comprobaciones OK).

### 6.1 Configuración de cada cuenta especial (script 03)

| Cuenta | Configuración aplicada | Requisito del Anexo I | Pendiente |
|---|---|---|---|
| recepcion.bcn | Solo inicia sesión en **BCN-RECEPCION** (`userWorkstations`); no puede cambiar su contraseña; la contraseña no caduca; grupo `G_Recepcion` | Solo en el equipo de recepción, no cambia contraseña, perfil obligatorio, sin carpeta personal, consulta de Comun | Perfil obligatorio (GPO/servidor de ficheros); crear el equipo BCN-RECEPCION; permisos de consulta en Comun |
| auditor.ext | Creada **deshabilitada**; horario L-V 8:00-20:00; grupo `G_Auditor_Externo`; el script no la vuelve a deshabilitar | Deshabilitada hasta que lo indique el profesorado, caduca al final de la Fase 3, horario L-V 8-20 | **Fecha de caducidad** (fin de la Fase 3): `-CaducidadAuditor AAAA-MM-DD`; permisos de consulta en Sistemas\Documentacion y Legal\Comite_Seguridad |
| svc_backup, svc_web, svc_bbdd, svc_ia | Contraseña aleatoria de **32 caracteres**, no caduca, la cuenta no puede cambiarla; grupo `G_Cuentas_Servicio` | Sin inicio de sesión interactivo, mínimo privilegio, contraseñas largas gestionadas de forma segura | GPO que deniega el inicio de sesión local y por RDP a `G_Cuentas_Servicio`; privilegio de copia de seguridad para svc_backup |

### 6.2 Logins de SQL Server (no son cuentas del dominio)

| Login | Dónde | Permisos | Uso |
|---|---|---|---|
| `sa` | LNX01, LNX02, BKP01 | `sysadmin` | Solo administración (`sqlcmd`); nunca en aplicaciones |
| `pacemakerLogin` | LNX01, LNX02, BKP01 | `ALTER, CONTROL, VIEW DEFINITION` sobre `sqlag_cibernova` y `VIEW SERVER STATE` (24/11) | Agente de Pacemaker (`/var/opt/mssql/secrets/passwd`, `400 root`) |
| `web_cibernova` | LNX01 y LNX02, **mismo SID** (26/11) | `db_datareader` + `db_datawriter` en `cibernova_pruebas` | Web (`/etc/cibernova/web.ini`, `640 root:www-data`). Mejora prevista: sustituirlo por `svc_web` del dominio |
| | | **27/11:** en `cibernova_portal`, solo `SELECT, INSERT, UPDATE` sobre `dbo.incidencias` (sin `DELETE` ni cambios de esquema) | Portal CiberNova |
| `backup_cibernova` | LNX01 y LNX02, **mismo SID** (27/11) | `db_backupoperator` en `cibernova_pruebas` y `cibernova_portal` (no es `sysadmin`) | Copias `COPY_ONLY` antes de cada trabajo de Bareos (`bareos-sql-backup.sh`; credenciales en `/root/.sqlbackup.cred`, solo root) |

**Decisiones (16/11/2026):**
- **Cuentas de servicio normales en lugar de gMSA.** Las gMSA (la contraseña la cambia Windows automáticamente) solo funcionan en servidores Windows, y `svc_web`, `svc_bbdd` y `svc_ia` se usarán en Ubuntu. Para tener un único procedimiento se usan cuentas normales con contraseñas de 32 caracteres guardadas cifradas, con rotación manual documentada (memoria técnica, apartado 5.4).
- **`recepcion.bcn` y las svc_ con contraseña que no caduca:** como no pueden cambiar su propia contraseña, si caducara la cuenta quedaría bloqueada. La cambia Sistemas según el procedimiento.
- **`recepcion.bcn` no está en `G_Sede_Barcelona`:** ese grupo podrá modificar `Comun\Sedes\Barcelona` (P-43) y recepción solo puede consultar Comun (P-44).
- Nombre del equipo de recepción: **BCN-RECEPCION**.

---

## 7. Scripts

| Script | Función |
|---|---|
| [`scripts/windows/01-crear-ou-grupos.ps1`](../../scripts/windows/01-crear-ou-grupos.ps1) (v2.1) | OU (incluidas Equipos y Servidores) y grupos globales (incluidos G_Politica_15 y G_Admin_Sistemas) |
| [`scripts/windows/02-alta-usuarios.ps1`](../../scripts/windows/02-alta-usuarios.ps1) (v2.2) | Políticas de contraseña, 89 empleados, grupos, restricciones de becarios, 6 cuentas adm. y sus privilegios. Errores de la v1 y correcciones: [memoria técnica, apartado 5.2](03-memoria-tecnica.md#52-error-de-la-versión-1-y-corrección) |
| [`scripts/windows/03-cuentas-especiales.ps1`](../../scripts/windows/03-cuentas-especiales.ps1) (v1.0) | recepcion.bcn, auditor.ext y las 4 cuentas de servicio, con sus restricciones y grupos |
| [`scripts/windows/04-configurar-dns.ps1`](../../scripts/windows/04-configurar-dns.ps1) (v1.0) | Configuración del DNS de DC01 (pendiente de ejecutar) |
| [`scripts/windows/07-personales-cuotas-perfiles.ps1`](../../scripts/windows/07-personales-cuotas-perfiles.ps1) (v1.0) | 89 carpetas personales (solo el usuario con Modificar), unidad H: y perfil móvil en AD, recurso `Perfiles$` y cuotas FSRM (2 GB / 5 GB / 500 MB, aviso al 90 %); en FS02 solo las cuotas (`-SoloCuotas`). **Pendiente:** que el script de alta lo llame en cada alta (Anexo I) [PENDIENTE DE CONFIRMAR] |
| [`scripts/windows/06-carpetas-permisos.ps1`](../../scripts/windows/06-carpetas-permisos.ps1) (v1.3) | 50 carpetas del Anexo I, 63 grupos `DL_` + `G_RRHH_Nominas_Consulta`, permisos NTFS de la matriz y auditoría (SACL) en Nominas, Expedientes y Proyectos\Sanitario. Modo `-Simular`; idempotente |
| [`scripts/windows/96-comprobar-carpetas-permisos.ps1`](../../scripts/windows/96-comprobar-carpetas-permisos.ps1) (v1.2) | Compara AD y las ACL con la matriz (solo lee); en FS01 y FS02 |
| Movimientos de personal | **[PENDIENTE]** (Anexo I, apartado 11) |

## 8. Pendiente para completar el inventario

- [x] Matriz de permisos (carpetas en filas, grupos en columnas): [`08-matriz-permisos.md`](08-matriz-permisos.md) (26/11).
- [ ] Diagrama de OU y de anidamiento de grupos.
- [ ] Script de movimientos de personal.
- [ ] Evidencias de las 15 pruebas de verificación.
- [ ] Carpetas personales creadas por el script de alta (hoy las crea el script 07, 26/11).

Lista completa: [`docs/gestion/lista-tareas-fase1.md`](../gestion/lista-tareas-fase1.md) (apartados 2, 5, 6 y 15).
