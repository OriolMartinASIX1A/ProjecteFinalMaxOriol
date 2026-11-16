# Guía de instalación del hipervisor (Proxmox VE)

**Grupo 3:** Max · Oriol
**Versión:** 0.2 · 16/11/2026 · Basada en la instalación real del equipo

> Objetivo: que cualquier persona pueda reinstalar el host desde cero con el mismo resultado. Los datos marcados con **[PENDIENTE DE CONFIRMAR]** hay que comprobarlos en el servidor.

---

## 1. Elección de la plataforma

Se eligió **Proxmox VE** por estos motivos (la comparación con otras alternativas está en el [documento de diseño](01-documento-diseno.md#31-plataforma-de-virtualización-proxmox-ve-9x)):

- **Es gratuito.** Motivo principal: no requiere licencia para su uso básico.
- **Gestión centralizada** desde una interfaz web.
- **Preparado para crecer:** permite unir varios servidores físicos en un clúster.

## 2. Hardware

| Componente | Valor |
|---|---|
| CPU | 2× Intel Xeon E5-2620 v2 (6 núcleos cada uno) |
| RAM | 128 GB |
| Discos | 4× 900 GB |
| Red | 4 interfaces (`nic0`–`nic3`); **solo una conectada (UP)** |

## 3. Preparación del medio de instalación

1. Descargar la **imagen ISO** de Proxmox VE desde la web oficial. Versión utilizada en la instalación definitiva: **Proxmox VE 9.2.21** (la misma que usaban otros grupos del aula).
2. Grabar la ISO en un **pendrive** con **Rufus** para que el servidor pueda arrancar desde él.

## 4. Configuración del almacenamiento: RAID 10

Antes de instalar nada, se creó un **RAID 10** con los 4 discos desde la configuración de discos del servidor (BIOS / utilidad de la controladora).

- **Espejo (RAID 1):** los datos se duplican en parejas de discos.
- **Reparto (RAID 0):** los datos se distribuyen entre las parejas para ganar rendimiento.
- Resultado: buen rendimiento y tolerancia a fallos (sigue funcionando aunque falle un disco de cada pareja). Se aprovecha el 50 % de la capacidad: **~1,8 TB útiles**.

El instalador de Proxmox vio el RAID como un **único disco (`/dev/sda`)**, lo que indica que el RAID lo gestiona la controladora. **[PENDIENTE DE CONFIRMAR]** con `lsblk` (debe aparecer un solo disco de ~1,8 TB).

## 5. Instalación de Proxmox VE

1. Entrar en la **BIOS** y arrancar desde el pendrive.
2. Ejecutar el instalador gráfico con estos parámetros:

| Parámetro | Valor |
|---|---|
| Sistema de archivos | ext4 (Proxmox crea `local` y `local-lvm` con LVM-thin) |
| Disco de destino | `/dev/sda` (el volumen RAID 10) |
| País / zona horaria / teclado | España / Europe/Madrid / es |
| Interfaz de gestión | `eno1` **[PENDIENTE DE CONFIRMAR]**: en el sistema instalado las interfaces se llaman `nic0`–`nic3` |
| Nombre del host (nodo) | `PROC` (en la instalación inicial era `poxmox3`; el nombre actual del nodo es `PROC`) |
| Dirección IP (CIDR) | 192.168.202.3/**22** (corregido en la memoria el 16/11; antes ponía /24, ver 5.1). Confirmar en el host con `ip -br addr show vmbr0` |
| Puerta de enlace | 192.168.200.254 |
| DNS | 192.168.200.254 |
| Correo del administrador | correo del centro de Max |

3. Confirmar el resumen. El instalador particiona el disco, copia los ficheros y reinicia.

### 5.1 Importante: máscara de red

La red del aula es **192.168.200.0/22** (255.255.252.0), que va de 192.168.200.0 a 192.168.203.255. La puerta de enlace (192.168.200.254) solo es alcanzable si la máscara es **/22**:

- Con **/24**, el servidor cree que su red es 192.168.202.0–192.168.202.255 y la puerta de enlace .200.254 queda **fuera** → no hay salida a Internet ni actualizaciones.
- Con **/22**, la puerta de enlace está dentro de la red → funciona.

Para comprobarlo en el host:

```bash
ip -br addr show vmbr0      # debe mostrar 192.168.202.3/22
ip route                    # debe haber "default via 192.168.200.254 dev vmbr0"
ping -c 3 192.168.200.254   # la puerta de enlace responde
ping -c 3 deb.debian.org    # hay salida a Internet y DNS
```

Si sale /24, corregirlo en *Datacenter → nodo → System → Network → vmbr0* (CIDR `192.168.202.3/22`) y aplicar la configuración.

## 6. Verificación

1. Al arrancar, la consola muestra la dirección del panel web: **https://192.168.202.3:8006/** (puerto 8006).
2. Con `ip a` se comprueba que:
   - Se detectan las 4 interfaces físicas (`nic0`–`nic3`) y **una está UP**.
   - Existe el puente **`vmbr0`** con la IP del host. Es el puente al que se conectan las VMs.

**Capturas:** pantalla de resumen del instalador, consola con la URL de acceso, `ip a`, `pveversion`, `lsblk` y el panel web.

## 7. Post-instalación: script "PVE Post Install"

Después de la instalación se ejecutó desde la shell de Proxmox el script **PVE Post Install** de [community-scripts.org](https://community-scripts.org/scripts/post-pve-install). Lo que hace:

1. **Repositorios:**
   - Deshabilita el repositorio *Enterprise* (da errores al actualizar sin suscripción de pago).
   - Habilita el repositorio *No-Subscription* (gratuito y oficial para la comunidad).
   - Corrige las fuentes de Debian/Proxmox.
   - Opcionalmente añade el repositorio de pruebas (*Test*). **[PENDIENTE DE CONFIRMAR]** si se activó: en un servidor que debe ser estable **no** debería activarse.
2. **Elimina el aviso de suscripción** que aparece al iniciar sesión en la web.
3. **Actualiza** todos los paquetes de Proxmox VE y Debian.
4. **Reinicia** al final si hay un kernel nuevo.

> Nota de seguridad: es un script de terceros que se ejecuta como root. Antes de ejecutarlo conviene revisar su código. Esto se valorará en la auditoría de la Fase 3.

## 8. Incidencias durante la instalación

| Intento | Resultado | Causa |
|---|---|---|
| 1.º | Fallido | Error del instalador. **[PENDIENTE DE CONFIRMAR]**: mensaje de error y causa |
| 2.º | Fallido | DNS y puerta de enlace mal configurados |
| 3.º | Correcto | Se revisó la configuración de red y se completó la instalación |
| 4.º (reinstalación) | Correcto | Con la versión instalada no se podía instalar Windows Server en ninguna VM. Se reinstaló Proxmox con la versión 9.2.21, la que usaban otros grupos. Aun así, las VMs Windows iban tan lentas que no se podía trabajar (sin un error concreto) y se pasó a crearlas en VirtualBox (ver apartado 9) |

**Lección aprendida:** revisar los datos de red antes de pulsar «Instalar». La puerta de enlace tiene que estar dentro de la red definida por la IP y la máscara; un error obliga a repetir toda la instalación.

## 9. Rendimiento de las VMs Windows

Las VMs Windows iban muy lentas en Proxmox. No se llegó a medir la causa; estas son las más probables en este hardware y cómo comprobarlas. **[PENDIENTE DE COMPROBAR]** en la primera VM Windows importada.

| Posible causa | Cómo comprobarlo | Solución |
|---|---|---|
| La consola web (noVNC) va lenta, no la VM | Conectarse por Escritorio remoto (RDP) y comparar | Trabajar por RDP |
| Caché de escritura de la controladora RAID desactivada (batería agotada o sin batería) | En el host: `pveperf /var/lib/vz` → si *FSYNCS/SECOND* sale por debajo de ~200, la escritura es muy lenta | Activar la caché de escritura en la utilidad de la controladora (si la batería está bien) |
| Disco emulado (IDE/SATA) en vez de VirtIO | *VM → Hardware → Hard Disk* | VirtIO SCSI single + *IO thread*, instalando antes los drivers de `virtio-win.iso` |
| Tarjeta de red emulada (E1000) | *VM → Hardware → Network Device* | VirtIO (con los drivers de `virtio-win.iso`) |
| Tipo de CPU genérico | *VM → Hardware → Processors → Type* | `host` (las VMs no se migran a otro host, así que no hay inconveniente) |
| Poca RAM o *ballooning* sin driver | *VM → Hardware → Memory* | 4 GB fijos como mínimo para Windows Server |

**Capturas:** resultado de `pveperf` y la configuración de hardware de la VM antes y después.

## 10. Pendiente en el host

- [ ] Confirmar máscara (`ip -br addr`), disco (`lsblk`) e interfaces (`ip -br link`).
- [ ] Orden de arranque de las VMs (DC → BKP → FS → LNX → clientes) en *VM → Options → Start/Shutdown order*.
- [ ] Valorar con el profesorado conectar una segunda NIC para un bond active-backup.
