# Versiones del paquete

Cada paquete que se entrega se llama `CiberNova_G3_Vx.zip`. Este fichero dice qué versión es y qué cambió.

| Paquete | Fecha | Cambios |
|---|---|---|
| **V7** | 16/11/2026 | Primera subida al repositorio de GitHub (sin zip). DC01 completo: scripts 01 v2.1 y 03 ejecutados (23 OU, 27 grupos, 26 comprobaciones OK); documentos revisados y tareas hechas actualizadas; memoria del proyecto en PDF |
| V6 | 16/11/2026 | Bitácora: estructura y contenido de las carpetas de trabajo de DC01 (`C:\CiberNova` y `C:\CiberNova-Privado`) |
| V5 | 16/11/2026 | `01-crear-ou-grupos.ps1` v2.1 (OU Equipos y Servidores). Diseño, memoria técnica (primer intento en Proxmox, OU) e inventario v0.4 actualizados; bitácora: decisión de las OU, aclaración del primer intento y exportación de DC01 aplazada al 17/11 |
| V4 | 16/11/2026 | Nuevo `92-comprobar-cuentas-especiales.ps1` v1.0. Bitácora: diagnóstico del reenviador DNS (el router del aula no da DNS ni Internet a DC01) y decisión de crear las cuentas especiales en la Fase 1. Memoria técnica: estado del DNS de DC01 |
| V3 | 16/11/2026 | Nuevos scripts de comprobación (solo lectura) para las capturas: `90-comprobar-ou-grupos.ps1` v1.0 y `91-comprobar-usuarios.ps1` v1.0. Bitácora: incidencia de los `$_` perdidos al copiar comandos |
| V2 | 16/11/2026 | Nuevo script `03-cuentas-especiales.ps1` v1.0 (recepcion.bcn, auditor.ext, svc_backup, svc_web, svc_bbdd, svc_ia). Inventario v0.3 (configuración y decisiones de las cuentas especiales), memoria técnica (apartado 5.4 y procedimiento de rotación de contraseñas), bitácora y calendario actualizados. Script 02 v2.2 ejecutado con éxito en DC01 |
| V1 | 16/11/2026 | Primer paquete numerado. Documento de diseño v0.2 (incluye red plana sin VLAN), guía del hipervisor v0.2, memoria técnica v0.2, inventario v0.2, calendario replanificado, bitácora al día. Scripts: `01-crear-ou-grupos.ps1` v2.0 y `02-alta-usuarios.ps1` v2.2 |
