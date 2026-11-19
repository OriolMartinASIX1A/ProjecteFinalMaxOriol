# Lista de tareas de la Fase 1 (control de requisitos)

**Grupo 3:** Max (Linux) · Oriol (Windows)
**Versión:** 1.5 · 19/11/2026 (sesión 2 Linux: SQL Server configurado en LNX01, LNX02 y BKP01; BKP02 creada) · v1.4 · 19/11/2026 (DC02 promovido y comprobado en VirtualBox; reenviadores de DC02) · v1.3 · 19/11/2026 (reenviadores corregidos, revisión general de documentos, DC02 en VirtualBox)

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
| DHCP | ⏳ ❓ permiso del profesorado | ⏳ Kea HA | ⏳ |
| Servidor web | ⏳ ❓ aplicación sin decidir | ⏳ Pacemaker + VIP | ⏳ |
| FTP/SFTP | ⏳ | ⏳ Pacemaker + VIP | ⏳ |
| Base de datos | ✅ SQL Server 2025 configurado (19/11): Enterprise Developer en LNX01/LNX02, Express en BKP01, Always On activado | ⏳ AG + Pacemaker | ⏳ |
| Ficheros con DFS | ⏳ | ⏳ DFS-N + DFS-R | ⏳ |
| Usuarios y grupos con permisos y accesos | ✅ usuarios y grupos globales · ⏳ grupos `DL_`, permisos, carpetas, GPO | — | 15 pruebas del Anexo I ⏳ |
| Backups | ⏳ | ⏳ BKP01 + BKP02 | Restauración ⏳ |

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
| HV-07 | Usuario de Proxmox con permisos mínimos para `fence_pve` | Max | ⏳ | Sin contraseña en documentos |
| HV-08 | Rendimiento de Windows en Proxmox (VirtIO, agente QEMU) | Oriol | ⏳ | Propuesta: drivers VirtIO antes de exportar el OVA |
| HV-09 | Copia de las VMs (norma 2 del enunciado: "copias actualizadas de su infraestructura") | Max | ❓ | Propuesta: `vzdump` de las VMs a BKP02 o a disco externo antes de la Fase 3 [PENDIENTE DE CONFIRMAR] |

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
| AD-11b | Exportar DC01 y DC02 a OVA e importarlos en Proxmox (123 y 124, DC01 primero, IP de nuevo) | ⏳ | De uno en uno (≈ 24 GB libres en `local`) · no volver a encender las copias de VirtualBox · 📸 `replsummary` y `nslookup` en Proxmox |
| AD-12 | Replicación DC01 ↔ DC02 (`repadmin /replsummary`, usuario de prueba) | ✅ | 19/11: 0 errores en las dos direcciones, 5 particiones correctas, SYSVOL compartido y en estado 4, usuario de prueba replicado. `dcdiag`: solo avisos DFSREvent/SystemLog de la promoción (16:27) · 📸 |
| AD-13 | Fuente de hora del PDC (DC01) | ✅ | 18/11: `hora.roa.es` y `es.pool.ntp.org` con `w32tm` (confirmado por Max) |
| AD-14 | Caducidad de `auditor.ext` al final de la Fase 3 | ❓ | Fecha sin comunicar |
| AD-15 | Uso real de `svc_web` y `svc_bbdd` en los servicios Linux (mínimo privilegio) | ❓ | Falta decidir: p. ej. `svc_web` como login de la web en SQL Server y `svc_bbdd` para la autenticación de AD de SQL Server (keytab) [PENDIENTE DE CONFIRMAR] |
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
| DOM-01 | FS01 y FS02 en la OU Servidores | Oriol | ⏳ | `Test-ComputerSecureChannel` 📸 |
| DOM-02 | LNX01, LNX02, BKP01, BKP02 con realmd + SSSD, solo `G_Admin_Sistemas` | Max | ⏳ | `realm list` 📸 · necesita Internet para `apt` ❓ |
| DOM-03 | CLI01 y CLI02 en la OU Equipos | Oriol | ❓ | ¿uno se llama `BCN-RECEPCION`? ¿qué sede? ¿Windows 11 Pro/Education? |
| DOM-04 | Host Proxmox (PROC) | — | ❓ | Propuesta: no se une |
| DOM-05 | `Get-ADComputer` con todas las máquinas en su OU | Oriol | ⏳ | 📸 |

## 5. Servidor de ficheros con DFS (Oriol)

| ID | Tarea | Estado | Notas / evidencia |
|---|---|---|---|
| FS-01 | FS01 (.25) y FS02 (.26): instalación limpia (VirtualBox → OVA → Proxmox), disco de datos | ⏳ | Tamaño del disco de datos: propuesta del diseño, en revisión ❓ |
| FS-02 | Espacio de nombres DFS de dominio `\\cibernova.local\empresa` con los nombres exactos del Anexo I (ap. 8) | ⏳ | El profesorado usa esos nombres en las pruebas |
| FS-03 | Replicación DFS-R FS01 ↔ FS02; FS01 con prioridad en las referencias | ⏳ | 📸 informe de estado de DFS-R |
| FS-04 | Estructura de carpetas creada por script | ⏳ | Script nuevo (propuesta: `05-carpetas-permisos.ps1`) |
| FS-05 | **Matriz de permisos** P-01 a P-44 (carpetas en filas, grupos en columnas) | ⏳ | Entregable del inventario (Anexo I ap. 12) |
| FS-06 | Grupos `DL_<Carpeta>_<Nivel>` y anidamiento `G_` → `DL_` (AGDLP) | ⏳ | Script; diagrama de anidamientos |
| FS-07 | Permisos NTFS según la matriz; decisión recurso compartido vs NTFS justificada | ⏳ | |
| FS-08 | Enumeración basada en acceso (ABE) en todos los recursos | ⏳ | Pruebas 3, 5, 14 |
| FS-09 | Depósito `RRHH\Buzon_Documentacion` (P-10) e `Comun\Intercambio` (P-41) con CREATOR OWNER | ⏳ | Pruebas 7 y 8 |
| FS-10 | Becarios con permisos reducidos sin denegaciones genéricas (P-17, P-21, P-31) y sin acceso nunca a Proyectos (P-38) | ⏳ | Decisión justificada |
| FS-11 | Auditoría de acceso en `Nominas`, `Expedientes` y `Proyectos\Sanitario`, también para Sistemas (P-11, P-39) | ⏳ | SACL + GPO de auditoría avanzada · prueba 15 |
| FS-12 | Carpetas personales `Personales\<usuario>` **creadas por el script de alta**, solo el usuario con Modificar | ⏳ | Ampliar el script 02 (nueva versión) · sin carpeta para recepcion, auditor, adm. y svc |
| FS-13 | Cuotas FSRM: 2 GB general, 5 GB Desarrollo y Sistemas, 500 MB becarios, aviso al 90 % y bloqueo | ⏳ | Prueba 12 |
| FS-14 | (Valorable) vaciado automático de `Intercambio` (archivos de más de 30 días) | ⏳ | Tarea programada o FSRM |
| FS-15 | `svc_backup` con privilegio de copia en FS01/FS02 | ⏳ | GPO |

## 6. GPO, perfiles y unidades de red (Oriol)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| GPO-01 | Perfil **móvil** para Dirección y Comercial | ⏳ | Prueba 9 |
| GPO-02 | Perfil local con **redirección** de Documentos y Escritorio para el resto | ⏳ | |
| GPO-03 | Perfil **obligatorio** para `recepcion.bcn` | ⏳ | Prueba 10 |
| GPO-04 | Unidades H:, G:, P: (solo con acceso a algún proyecto) y S: (también recepcion) | ⏳ | Preferencias de GPO con destino por grupo |
| GPO-05 | Denegar inicio de sesión interactivo a `G_Cuentas_Servicio` | ✅ | `GPO_Dominio_CuentasServicio` (script 05 v1.1, 18/11), aplicada en DC01; script 94: 25 OK |
| GPO-06 | Cuentas `adm.` sin inicio de sesión en equipos de usuarios | ⏳ | `GPO_Equipos_SinCuentasAdm` creada y vinculada (18/11); falta comprobarla en CLI01/CLI02 |
| GPO-07 | Firewall de Windows por GPO (compensación de la red plana) | ✅ | `GPO_Dominio_Firewall` (18/11), aplicada en DC01 (3 perfiles activados); falta comprobarla en el resto al unirlos |
| GPO-08 | Auditoría avanzada de acceso a archivos en FS01/FS02 | ⏳ | `GPO_Servidores_Auditoria` creada y vinculada (18/11); falta FS01/FS02 y las SACL de las carpetas (FS-11) |

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
| LNX-06 | Firewall (ufw/nftables) solo con los puertos necesarios | ⏳ | Compensación de la red plana |
| LNX-07 | Salida a Internet para `apt` desde el rango .23–.33 | ✅ | 17/11 con LNX01 (DNS públicos en netplan porque el DNS del aula no responde) |

## 9. Base de datos: SQL Server 2025 AG (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| DB-01 | SQL Server 2025 Enterprise Developer en LNX01 y LNX02 | ✅ | 19/11: `mssql-conf setup` (opción 2), `hadr.hadrenabled 1` y Agente activado. `sqlcmd` → Enterprise Developer, `alwayson = 1`. 📸 `lnx0x_mssql-status`, `lnx0x_mssql-comprobacion` |
| DB-02 | SQL Server Express en BKP01 (réplica de solo configuración) | ✅ | 19/11: `mssql-conf setup` (opción 4) y `hadr.hadrenabled 1` (sin Agente: Express no lo incluye). `sqlcmd` → Express, `alwayson = 1`. Falta añadirla al AG como réplica de solo configuración (DB-03/04). 📸 `bkp01_mssql-*` |
| DB-03 | Always On AG con commit síncrono, endpoints con certificados | ⏳ | |
| DB-04 | AG como recurso de Pacemaker, listener en la VIP .27 | ⏳ | Punto de control 1/12 (plan B: conmutación manual) |
| DB-05 | Base de datos de la aplicación web | ❓ | Depende de la aplicación |
| DB-06 | Acceso a la BBDD solo desde los nodos web y BKP01 | ⏳ | Firewall |

## 10. Clúster Pacemaker + Corosync (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| HA-01 | Clúster `cibernova-g3` (LNX01, LNX02) en unicast, qdevice en BKP01 | ⏳ | |
| HA-02 | Fencing `fence_pve` contra Proxmox | ⏳ | HV-07 |
| HA-03 | VIP .27 junto al primario del AG | ⏳ | |

## 11. Web (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| WEB-01 | Decidir la aplicación web (debe usar SQL Server) | ❓ | |
| WEB-02 | Apache mpm_event + PHP-FPM + driver ODBC + `sqlsrv` en LNX01 y LNX02 | ⏳ | |
| WEB-03 | Mismo contenido web en los dos nodos | ❓ | Falta decidir cómo (despliegue desde Git, rsync…) |
| WEB-04 | Apache como recurso de Pacemaker con la VIP | ⏳ | |

## 12. SFTP (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| SFTP-01 | SFTP con chroot en LNX01 y LNX02 | ⏳ | |
| SFTP-02 | Quién usa el SFTP (usuarios de AD o locales) y qué carpeta | ❓ | |
| SFTP-03 | Mismas claves de host SSH en los dos nodos (sin aviso tras conmutar) y mismos datos | ⏳ | |

## 13. DHCP (Max)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| DHCP-01 | Permiso del profesorado para un DHCP propio en la red del aula | ❓ | |
| DHCP-02 | Kea HA hot-standby en LNX01/LNX02, solo clientes conocidos (reservas) | ⏳ | Opciones: DNS .23/.24, dominio `cibernova.local` |

## 14. Copias de seguridad: Bareos (Max, con Oriol para Windows)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| BKP-01 | Bareos Director + almacenamiento en BKP01; almacenamiento en BKP02 | ⏳ | |
| BKP-02 | Agentes en los Windows (FS con VSS, DC con estado del sistema) y en los Linux | ⏳ | |
| BKP-03 | Copia de SQL Server desde la secundaria | ⏳ | |
| BKP-04 | Copy jobs BKP01 → BKP02 (3-2-1), programación y retenciones según RPO/RTO | ⏳ | ❓ RPO/RTO en revisión |
| BKP-05 | Director en *cold standby* en BKP02 + copia del catálogo | ⏳ | Punto único de fallo documentado |

## 15. Pruebas y evidencias (obligatorias)

| ID | Tarea | Estado | Notas |
|---|---|---|---|
| PR-01 | **15 pruebas del Anexo I** (ap. 10) con captura cada una | ⏳ | Necesitan FS, GPO y clientes |
| PR-02 | Caída de AD/DNS: DC01 apagado, el cliente sigue | ⏳ | 📸 |
| PR-03 | Caída de ficheros: FS01 apagado, DFS sigue con FS02 | ⏳ | 📸 |
| PR-04 | Caída de BBDD/web/SFTP: LNX01 apagado, la VIP pasa a LNX02 | ⏳ | 📸 |
| PR-05 | Caída de DHCP: el nodo en espera responde | ⏳ | 📸 |
| PR-06 | Restauración de copias (archivo, BBDD) y con BKP01 apagado | ⏳ | 📸 |
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
| DOC-09 | Repositorio Git: commits significativos con conventional commits | ⏳ Continuo | **Todo subido el 4/12**. GitHub va por la V11 (17/11): subir V13. Los 3 primeros commits salen con autor Claude (registrado en la bitácora 19/11); los nuevos, con autoría de Max u Oriol. Propuesta: un commit por sesión y ramas por bloque [PENDIENTE DE CONFIRMAR]. Carpetas `scripts/linux`, `configs/*` y `docs/diagramas` vacías |
| DOC-10 | Memoria del proyecto (Google Doc → `docs/Proyecto-memoria.pdf`) | ⏳ | Regenerar el PDF con las capturas nuevas |
| DOC-11 | Defensa: 5-10 min, los dos participan, demo funcional | ⏳ | ❓ fecha de la defensa |

## 17. Preguntas para el profesorado

| ID | Pregunta | Afecta a |
|---|---|---|
| Q-01 | ¿Se permite un DHCP propio (solo clientes conocidos) en la red del aula? | DHCP-01 |
| Q-02 | ¿Se esperan VLAN en la Fase 1? | Diseño 3.11 |
| Q-03 | El rango .23–.33 tiene Internet (18/11) pero el DNS está interceptado: ¿puede tener DNS sin interceptar? ¿Hay un NTP recomendado? | LNX-07, AD-13, DNS-06 |
| Q-04 | Fecha de la defensa y si las sesiones del 10/12 y 15/12 sirven para la demo | DOC-11, calendario |
| Q-05 | Fin de la Fase 3 (caducidad de `auditor.ext`) | AD-14 |
| Q-06 | ¿Se puede cablear una segunda NIC del host? | HV-04 |
