# 08. Matriz de permisos de carpetas compartidas (P-01 a P-44)

**Proyecto:** CiberNova Solutions | Grupo 3 | Fase 1
**Responsable:** Oriol (Windows) | **Revisión:** Max [PENDIENTE DE CONFIRMAR]
**Versión:** 1.0 (26/11/2026) | **Script asociado:** `scripts/windows/06-carpetas-permisos.ps1` v1.3 (comprobación: `96-comprobar-carpetas-permisos.ps1` v1.2)
**Estado:** propuesta. Simulada con los 89 usuarios de `usuarios_cibernova.csv`: 0 errores en P-01 a P-44 y pruebas 1-8 y 13 del Anexo I correctas. Aún no se ha aplicado en FS01.

## 1. Modelo: AGDLP

Los permisos nunca se dan a usuarios ni a grupos globales directamente:

**A**ccount (usuario) -> **G**lobal (`G_<Departamento>`, script 01) -> **DL** (`DL_<Carpeta>_<Nivel>`, dominio local) -> **P**ermiso NTFS.

- Si alguien cambia de departamento, solo se le cambia el grupo G_: los permisos le siguen solos.
- Si cambia el permiso de una carpeta, solo se toca el grupo DL_ (quién está dentro), no la ACL.
- En las ACL solo aparecen grupos DL_, así que la ACL se lee igual que la matriz.

**Alternativas descartadas:** permisos directos a usuarios (inmanejable con 89 personas y prohibido por el propio Anexo I), y permisos a los G_ directamente (AGP: funciona, pero mezcla "quién es" con "qué puede hacer" y cada cambio obliga a tocar las ACL).

"Todos los empleados" = `G_Sede_Barcelona` + `G_Sede_Madrid` + `G_Sede_Valencia` (89 personas, becarios incluidos). Recepción, el auditor externo y las cuentas `adm.*` no están en ninguna sede y solo reciben lo que la matriz les da de forma explícita.

## 2. Niveles

| Nivel | Significado | Cómo se aplica en NTFS |
|---|---|---|
| **CT** | Control total | FullControl, heredado |
| **M** | Modificación (leer, crear, cambiar, borrar; **no** cambiar permisos) | Modify, heredado |
| **C** | Consulta | Lectura y ejecución, heredado |
| **L** | Listar solo esta carpeta, para llegar a una subcarpeta | Listar carpeta, **no** heredado. Con ABE el usuario solo ve dentro lo que puede abrir |
| **D** | Depósito: deja ficheros y solo ve y gestiona los suyos | Listar + crear ficheros/carpetas solo en esta carpeta; `CREATOR OWNER` con Modificar solo en lo que hay dentro |
| **I** | Intercambio: ve todo, crea, y solo modifica/borra lo suyo | Lectura heredada + crear solo en esta carpeta; `CREATOR OWNER` con Modificar |
| **X** | Denegar todo | Deny FullControl, heredado (solo `DL_Proyectos_Denegar` <- `G_Becarios`, P-38) |

En todas las carpetas con la herencia cortada (SH) hay tres reglas base: **SYSTEM** y **Administradores** con control total (las cuentas `adm.*` son administradores del dominio: "control total técnico"), y **DERECHOS DE PROPIETARIO** (OWNER RIGHTS) con solo "leer permisos".

## 3. Decisiones y justificación (para la memoria)

1. **Becarios con grupos propios, sin denegaciones genéricas.** El script 02 ya saca a los becarios de `G_<Departamento>` y los mete en `G_Becarios_<Dept>`. Así el becario no hereda nada del departamento y solo recibe lo que la matriz le da. *Alternativa descartada:* dejarlos en el departamento y denegar carpeta a carpeta: una denegación gana a cualquier permiso y es fácil bloquear sin querer a alguien que está en dos grupos.
2. **Una sola denegación, en Proyectos (P-38).** Se pone de forma explícita en la raíz de Proyectos y otra vez en Sanitario y Financiero, porque un permiso explícito en una subcarpeta ganaría a una denegación heredada (orden de evaluación de NTFS).
3. **Nivel L + ABE en las raíces.** Para que cada uno llegue a "su" carpeta sin ver las de los demás. ABE ya está activado en el espacio de nombres DFS y en los recursos compartidos (FS-03).
4. **OWNER RIGHTS con solo "leer permisos".** Por defecto el creador de un fichero puede cambiar sus permisos aunque tenga nivel M. Esta regla se lo quita: el nivel M del Anexo I queda de verdad sin "cambiar permisos".
5. **Nuevo grupo global `G_RRHH_Nominas_Consulta`** (rosa.martinez, P-08). Los permisos van siempre a grupos; si mañana otra persona tiene que consultar nóminas, se añade al grupo.
6. **Permisos abiertos en el recurso compartido y reales en NTFS.** Los recursos `$` dan Control total a Usuarios autentificados en SMB, y es NTFS quien decide. Así solo hay un sitio donde mirar los permisos y no se suman restricciones difíciles de depurar.
7. **Auditoría** (éxito y error de lectura, escritura, borrado y cambio de permisos, para Todos) en `RRHH\Nominas`, `RRHH\Expedientes` y `Proyectos\Sanitario` (P-11, P-39). Se audita también a Sistemas: precisamente quien tiene más acceso es quien más interesa vigilar. Necesita la GPO `GPO_Servidores_Auditoria` (categoría "Sistema de archivos").
8. **`svc_backup` no aparece en ninguna ACL.** Lee todo con el privilegio "Hacer copias de seguridad" (GPO, FS-15), que se salta las ACL solo para leer.
9. **Las ACL se replican a FS02 por DFS-R**: el script solo se ejecuta en FS01.

## 4. Matriz (nivel efectivo por grupo)

Leyenda: **(SH)** = sin herencia (la carpeta no hereda permisos de la superior); **(AUD)** = auditada; celda vacía = sin acceso. Las subcarpetas sin (SH) heredan de la carpeta superior y añaden lo que indica su fila.

Columnas: **Dir** = `G_Direccion`; **Resp** = `G_Responsables`; **Adm** = `G_Administracion`; **RRHH** = `G_RRHH`; **RRHH_Nom** = `G_RRHH_Nominas`; **Nom_Cons** = `G_RRHH_Nominas_Consulta`; **Com** = `G_Comercial`; **Mkt** = `G_Marketing`; **Cons** = `G_Consultoria`; **Des** = `G_Desarrollo`; **Sis** = `G_Sistemas`; **Sop** = `G_Soporte`; **Leg** = `G_Legal`; **Comite** = `G_Comite_Seguridad`; **P_San** = `G_Proyecto_Sanitario`; **P_Fin** = `G_Proyecto_Financiero`; **Bec_Des** = `G_Becarios_Desarrollo`; **Bec_Mkt** = `G_Becarios_Marketing`; **Bec_Sop** = `G_Becarios_Soporte`; **Becarios** = `G_Becarios`; **Sede_BCN** = `G_Sede_Barcelona`; **Sede_MAD** = `G_Sede_Madrid`; **Sede_VAL** = `G_Sede_Valencia`; **Recep** = `G_Recepcion`; **Auditor** = `G_Auditor_Externo`.

| Carpeta | Dir | Resp | Adm | RRHH | RRHH_Nom | Nom_Cons | Com | Mkt | Cons | Des | Sis | Sop | Leg | Comite | P_San | P_Fin | Bec_Des | Bec_Mkt | Bec_Sop | Becarios | Sede_BCN | Sede_MAD | Sede_VAL | Recep | Auditor | Requisitos |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Departamentos** (SH) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | L | L | L |  | L |  |
| Departamentos\Direccion (SH) | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | L | L | L |  |  | P-01, P-02, P-03 |
| Departamentos\Direccion\Actas  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Direccion\Estrategia  | M | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-02 |
| Departamentos\Direccion\Comunicados  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | C | C |  |  | P-03 |
| Departamentos\Administracion (SH) | C |  | M |  |  |  | L |  |  |  |  |  | L |  |  |  |  |  |  |  |  |  |  |  |  | P-04, P-05, P-06 |
| Departamentos\Administracion\Contabilidad  | C |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Administracion\Facturacion  | C |  | M |  |  |  |  |  |  |  |  |  | C |  |  |  |  |  |  |  |  |  |  |  |  | P-06 |
| Departamentos\Administracion\Presupuestos  | C |  | M |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-05 |
| Departamentos\RRHH (SH) |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | L | L | L |  |  | P-07, P-08, P-09, P-10 |
| Departamentos\RRHH\Expedientes (AUD) | C |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-09, P-11 |
| Departamentos\RRHH\Nominas (SH) (AUD) |  |  |  |  | M | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-08, P-11 |
| Departamentos\RRHH\Seleccion  | C |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-09 |
| Departamentos\RRHH\Buzon_Documentacion  |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | D | D | D |  |  | P-10 |
| Departamentos\Comercial (SH) | C |  |  |  |  |  | M | C | L |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-12, P-13, P-14 |
| Departamentos\Comercial\Clientes  | C |  |  |  |  |  | M | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Comercial\Ofertas  | C |  |  |  |  |  | M | C | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | P-14 |
| Departamentos\Marketing (SH) | C |  |  |  |  |  | L | M |  |  |  |  |  |  |  |  |  | C |  |  |  |  |  |  |  | P-15, P-16, P-17 |
| Departamentos\Marketing\Campanas  | C |  |  |  |  |  | M | M |  |  |  |  |  |  |  |  |  | M |  |  |  |  |  |  |  | P-16, P-17 |
| Departamentos\Marketing\Diseno  | C |  |  |  |  |  |  | M |  |  |  |  |  |  |  |  |  | C |  |  |  |  |  |  |  |  |
| Departamentos\Consultoria (SH) | C |  |  |  |  |  |  |  | M | M |  | C |  |  |  |  |  |  |  |  |  |  |  |  |  | P-18, P-19 |
| Departamentos\Consultoria\Metodologia  | C |  |  |  |  |  |  |  | M | M |  | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Consultoria\Informes  | C |  |  |  |  |  |  |  | M | M |  | C |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Desarrollo (SH) |  |  |  |  |  |  |  |  | L | M | L | L |  |  |  |  | L |  |  |  |  |  |  |  |  | P-20, P-21, P-22, P-23 |
| Departamentos\Desarrollo\Codigo  |  |  |  |  |  |  |  |  | C | M |  |  |  |  |  |  | C |  |  |  |  |  |  |  |  | P-21, P-23 |
| Departamentos\Desarrollo\Releases  |  |  |  |  |  |  |  |  |  | M | C | C |  |  |  |  | C |  |  |  |  |  |  |  |  | P-21, P-22 |
| Departamentos\Desarrollo\Becarios  |  |  |  |  |  |  |  |  |  | M |  |  |  |  |  |  | M |  |  |  |  |  |  |  |  | P-21 |
| Departamentos\Sistemas (SH) |  |  |  |  |  |  |  |  |  |  | CT | L |  |  |  |  |  |  |  |  |  |  |  |  | L | P-24, P-25, P-27 |
| Departamentos\Sistemas\Documentacion  |  |  |  |  |  |  |  |  |  |  | CT | C |  |  |  |  |  |  |  |  |  |  |  |  | C | P-25, P-27 |
| Departamentos\Sistemas\Software  |  |  |  |  |  |  |  |  |  |  | CT | C |  |  |  |  |  |  |  |  |  |  |  |  |  | P-25 |
| Departamentos\Sistemas\Privado  |  |  |  |  |  |  |  |  |  |  | CT |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| Departamentos\Soporte (SH) |  |  |  |  |  |  |  |  |  |  | M | M |  |  |  |  |  |  | C |  | L | L | L |  |  | P-28, P-29, P-30, P-31 |
| Departamentos\Soporte\Incidencias  |  |  |  |  |  |  |  |  | C | C | M | M |  |  |  |  |  |  | M |  |  |  |  |  |  | P-29, P-31 |
| Departamentos\Soporte\Base_Conocimiento  |  |  |  |  |  |  |  |  |  |  | M | M |  |  |  |  |  |  | C |  | C | C | C |  |  | P-30 |
| Departamentos\Legal (SH) |  |  |  |  |  |  |  |  |  |  |  |  | M |  |  |  |  |  |  |  | L | L | L |  | L | P-32, P-33, P-34, P-35 |
| Departamentos\Legal\Contratos  | C |  | C |  |  |  | C |  |  |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  | P-33 |
| Departamentos\Legal\Politicas  |  |  |  |  |  |  |  |  |  |  | M |  | M |  |  |  |  |  |  |  | C | C | C |  |  | P-34 |
| Departamentos\Legal\Comite_Seguridad (SH) |  |  |  |  |  |  |  |  |  |  |  |  |  | M |  |  |  |  |  |  |  |  |  |  | C | P-35 |
| **Proyectos** (SH) | L |  |  |  |  |  |  |  |  |  |  |  | L |  | L | L |  |  |  | X |  |  |  |  |  | P-36, P-37, P-38 |
| Proyectos\Sanitario (AUD) | C |  |  |  |  |  |  |  |  |  |  |  | C |  | M |  |  |  |  | X |  |  |  |  |  | P-36, P-38, P-39 |
| Proyectos\Financiero  | C |  |  |  |  |  |  |  |  |  |  |  | C |  |  | M |  |  |  | X |  |  |  |  |  | P-37, P-38 |
| **Comun** (SH) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | C | C | C |  | P-40, P-42, P-43, P-44 |
| Comun\Plantillas  |  |  |  |  |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  | C | C | C | C |  | P-40 |
| Comun\Intercambio (SH) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | I | I | I |  |  | P-41, P-44 |
| Comun\Formacion  |  |  |  | M |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | C | C | C |  | P-42 |
| Comun\Sedes  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | C | C | C |  |  |
| Comun\Sedes\Barcelona  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | M | C | C | C |  | P-43 |
| Comun\Sedes\Madrid  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | M | C | C |  | P-43 |
| Comun\Sedes\Valencia  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | C | C | M | C |  | P-43 |
| **Personales** (SH) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | L | L | L |  |  |  |

## 5. Grupos de dominio local (63)

| Grupo DL_ (dominio local) | Nivel | Miembros (grupos globales) | Se aplica en | Requisitos |
|---|---|---|---|---|
| `DL_Departamentos_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia`, `G_Auditor_Externo` | `Departamentos` |  |
| `DL_Direccion_M` | M | `G_Direccion` | `Departamentos\Direccion` | P-01 |
| `DL_Direccion_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\Direccion` | P-02, P-03 |
| `DL_Direccion_Estrategia_C` | C | `G_Responsables` | `Departamentos\Direccion\Estrategia` | P-02 |
| `DL_Direccion_Comunicados_C` | C | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\Direccion\Comunicados` | P-03 |
| `DL_Administracion_M` | M | `G_Administracion` | `Departamentos\Administracion` | P-04 |
| `DL_Administracion_C` | C | `G_Direccion` | `Departamentos\Administracion` | P-04 |
| `DL_Administracion_L` | L | `G_Comercial`, `G_Legal` | `Departamentos\Administracion` | P-05, P-06 |
| `DL_Administracion_Facturacion_C` | C | `G_Legal` | `Departamentos\Administracion\Facturacion` | P-06 |
| `DL_Administracion_Presupuestos_M` | M | `G_Comercial` | `Departamentos\Administracion\Presupuestos` | P-05 |
| `DL_RRHH_M` | M | `G_RRHH` | `Departamentos\RRHH` | P-07, P-10 |
| `DL_RRHH_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\RRHH` | P-08, P-09, P-10 |
| `DL_RRHH_Expedientes_C` | C | `G_Direccion` | `Departamentos\RRHH\Expedientes` | P-09, P-11 |
| `DL_RRHH_Nominas_M` | M | `G_RRHH_Nominas` | `Departamentos\RRHH\Nominas` | P-08, P-11 |
| `DL_RRHH_Nominas_C` | C | `G_RRHH_Nominas_Consulta` | `Departamentos\RRHH\Nominas` | P-08 |
| `DL_RRHH_Seleccion_C` | C | `G_Direccion` | `Departamentos\RRHH\Seleccion` | P-09 |
| `DL_RRHH_Buzon_D` | D | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\RRHH\Buzon_Documentacion` | P-10 |
| `DL_Comercial_M` | M | `G_Comercial` | `Departamentos\Comercial` | P-12 |
| `DL_Comercial_C` | C | `G_Direccion`, `G_Marketing` | `Departamentos\Comercial` | P-13 |
| `DL_Comercial_L` | L | `G_Consultoria` | `Departamentos\Comercial` | P-14 |
| `DL_Comercial_Ofertas_C` | C | `G_Consultoria` | `Departamentos\Comercial\Ofertas` | P-14 |
| `DL_Marketing_M` | M | `G_Marketing` | `Departamentos\Marketing` | P-15 |
| `DL_Marketing_C` | C | `G_Direccion`, `G_Becarios_Marketing` | `Departamentos\Marketing` | P-15, P-17 |
| `DL_Marketing_L` | L | `G_Comercial` | `Departamentos\Marketing` | P-16 |
| `DL_Marketing_Campanas_M` | M | `G_Comercial`, `G_Becarios_Marketing` | `Departamentos\Marketing\Campanas` | P-16, P-17 |
| `DL_Consultoria_M` | M | `G_Consultoria`, `G_Desarrollo` | `Departamentos\Consultoria` | P-18 |
| `DL_Consultoria_C` | C | `G_Soporte`, `G_Direccion` | `Departamentos\Consultoria` | P-19 |
| `DL_Desarrollo_M` | M | `G_Desarrollo` | `Departamentos\Desarrollo` | P-20 |
| `DL_Desarrollo_L` | L | `G_Becarios_Desarrollo`, `G_Sistemas`, `G_Soporte`, `G_Consultoria` | `Departamentos\Desarrollo` | P-21, P-22, P-23 |
| `DL_Desarrollo_Codigo_C` | C | `G_Becarios_Desarrollo`, `G_Consultoria` | `Departamentos\Desarrollo\Codigo` | P-21, P-23 |
| `DL_Desarrollo_Releases_C` | C | `G_Becarios_Desarrollo`, `G_Sistemas`, `G_Soporte` | `Departamentos\Desarrollo\Releases` | P-21, P-22 |
| `DL_Desarrollo_Becarios_M` | M | `G_Becarios_Desarrollo` | `Departamentos\Desarrollo\Becarios` | P-21 |
| `DL_Sistemas_CT` | CT | `G_Sistemas` | `Departamentos\Sistemas` | P-24 |
| `DL_Sistemas_L` | L | `G_Soporte`, `G_Auditor_Externo` | `Departamentos\Sistemas` | P-25, P-27 |
| `DL_Sistemas_Documentacion_C` | C | `G_Soporte`, `G_Auditor_Externo` | `Departamentos\Sistemas\Documentacion` | P-25, P-27 |
| `DL_Sistemas_Software_C` | C | `G_Soporte` | `Departamentos\Sistemas\Software` | P-25 |
| `DL_Soporte_M` | M | `G_Soporte`, `G_Sistemas` | `Departamentos\Soporte` | P-28 |
| `DL_Soporte_C` | C | `G_Becarios_Soporte` | `Departamentos\Soporte` | P-31 |
| `DL_Soporte_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\Soporte` | P-29, P-30 |
| `DL_Soporte_Incidencias_C` | C | `G_Consultoria`, `G_Desarrollo` | `Departamentos\Soporte\Incidencias` | P-29 |
| `DL_Soporte_Incidencias_M` | M | `G_Becarios_Soporte` | `Departamentos\Soporte\Incidencias` | P-31 |
| `DL_Soporte_BaseConocimiento_C` | C | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\Soporte\Base_Conocimiento` | P-30 |
| `DL_Legal_M` | M | `G_Legal` | `Departamentos\Legal` | P-32 |
| `DL_Legal_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia`, `G_Auditor_Externo` | `Departamentos\Legal` | P-33, P-34, P-35 |
| `DL_Legal_Contratos_C` | C | `G_Direccion`, `G_Administracion`, `G_Comercial` | `Departamentos\Legal\Contratos` | P-33 |
| `DL_Legal_Politicas_C` | C | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Departamentos\Legal\Politicas` | P-34 |
| `DL_Legal_Politicas_M` | M | `G_Sistemas` | `Departamentos\Legal\Politicas` | P-34 |
| `DL_Legal_ComiteSeguridad_M` | M | `G_Comite_Seguridad` | `Departamentos\Legal\Comite_Seguridad` | P-35 |
| `DL_Legal_ComiteSeguridad_C` | C | `G_Auditor_Externo` | `Departamentos\Legal\Comite_Seguridad` | P-35 |
| `DL_Proyectos_Denegar` | X | `G_Becarios` | `Proyectos`, `Proyectos\Sanitario`, `Proyectos\Financiero` | P-38 |
| `DL_Proyectos_L` | L | `G_Proyecto_Sanitario`, `G_Proyecto_Financiero`, `G_Legal`, `G_Direccion` | `Proyectos` | P-36, P-37, P-38 |
| `DL_Proyectos_Sanitario_M` | M | `G_Proyecto_Sanitario` | `Proyectos\Sanitario` | P-36, P-39 |
| `DL_Proyectos_Sanitario_C` | C | `G_Legal`, `G_Direccion` | `Proyectos\Sanitario` | P-38 |
| `DL_Proyectos_Financiero_M` | M | `G_Proyecto_Financiero` | `Proyectos\Financiero` | P-37 |
| `DL_Proyectos_Financiero_C` | C | `G_Legal`, `G_Direccion` | `Proyectos\Financiero` | P-38 |
| `DL_Comun_C` | C | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia`, `G_Recepcion` | `Comun` | P-40, P-42, P-43, P-44 |
| `DL_Comun_Plantillas_M` | M | `G_Marketing` | `Comun\Plantillas` | P-40 |
| `DL_Comun_Intercambio_I` | I | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Comun\Intercambio` | P-41, P-44 |
| `DL_Comun_Formacion_M` | M | `G_RRHH` | `Comun\Formacion` | P-42 |
| `DL_Comun_Sedes_Barcelona_M` | M | `G_Sede_Barcelona` | `Comun\Sedes\Barcelona` | P-43 |
| `DL_Comun_Sedes_Madrid_M` | M | `G_Sede_Madrid` | `Comun\Sedes\Madrid` | P-43 |
| `DL_Comun_Sedes_Valencia_M` | M | `G_Sede_Valencia` | `Comun\Sedes\Valencia` | P-43 |
| `DL_Personales_L` | L | `G_Sede_Barcelona`, `G_Sede_Madrid`, `G_Sede_Valencia` | `Personales` |  |

## 6. Ejemplo manual por interfaz gráfica: `RRHH\Nominas`

Antes de lanzar el script, Oriol hace esta carpeta a mano para entender qué hace el script. Después, el script la deja igual (es idempotente) y el 96 la comprueba.

**En DC01 - Usuarios y equipos de Active Directory**, en `CiberNova > Grupos`:
1. Nuevo > Grupo: `G_RRHH_Nominas_Consulta`, ámbito **Global**, tipo Seguridad. Miembros: `rosa.martinez`.
2. Nuevo > Grupo: `DL_RRHH_Nominas_M`, ámbito **Dominio local**. Miembros: `G_RRHH_Nominas`.
3. Nuevo > Grupo: `DL_RRHH_Nominas_C`, ámbito **Dominio local**. Miembros: `G_RRHH_Nominas_Consulta`.

**En FS01 - Explorador**, `D:\datos\Departamentos\RRHH\Nominas` (crear la carpeta si no existe):
4. Propiedades > Seguridad > Opciones avanzadas > **Deshabilitar herencia** > "Quitar todos los permisos heredados".
5. Agregar: SYSTEM y Administradores con Control total ("Esta carpeta, subcarpetas y archivos").
6. Agregar: DERECHOS DE PROPIETARIO, permisos avanzados, solo **Leer permisos**.
7. Agregar: `DL_RRHH_Nominas_M` con **Modificar**; `DL_RRHH_Nominas_C` con **Lectura y ejecución**.
8. Pestaña **Auditoría** > Agregar: entidad **Todos**, tipo **Todo** (éxito y error), permisos avanzados: Recorrer/ejecutar no; Leer datos, Crear archivos/escribir datos, Crear carpetas/anexar datos, Eliminar subcarpetas y archivos, Eliminar, Cambiar permisos, Tomar posesión.
9. Pestaña **Acceso efectivo**: seleccionar a `rosa.martinez` (debe salir solo lectura) y a un usuario de RRHH sin nóminas (sin acceso).

Capturas: `2026-MM-DD_sesionXX_DC01_grupos-nominas.png`, `..._FS01_nominas-seguridad.png`, `..._FS01_nominas-auditoria.png`, `..._FS01_nominas-acceso-efectivo.png`.

## 7. Orden de ejecución

1. Ejemplo manual de `RRHH\Nominas` (apartado 6).
2. En FS01: `powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1 -Simular` -> revisar la salida con Max.
3. En FS01: `powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1` (captura).
4. En FS01 y en FS02: `powershell -ExecutionPolicy Bypass -File .\96-comprobar-carpetas-permisos.ps1` (captura; debe dar 0 errores).
5. Pruebas 1-8 y 13 del Anexo I desde CLI01/CLI02 cuando estén unidos al dominio (los usuarios cogen los grupos nuevos al volver a iniciar sesión).
