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

---

## Entradas

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
