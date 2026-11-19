# ==========================================================
# CIBERNOVA - 04. CONFIGURACION DEL DNS EN DC01
# Dominio: cibernova.local
# Version: 1.2 (19/11/2026)
# Cambios 1.2: reenviadores 8.8.8.8 (Google) y 1.1.1.1 (Cloudflare),
#   que son los configurados de verdad en DC01 el 18/11 (la v1.1
#   decia 1.1.1.1 y 9.9.9.9 por error de anotacion). Nombres de
#   servicio www, sftp y sqlag confirmados (creados el 18/11).
# Cambios 1.1: reenviadores 1.1.1.1 y 9.9.9.9 en lugar de 192.168.200.254
#   (la red del aula intercepta el DNS y el .254 no responde; ver
#   bitacora 18/11/2026). Se mantienen las sugerencias de raiz.
# ----------------------------------------------------------
# Que hace (todo idempotente: se puede ejecutar varias veces):
#   1. Zona directa cibernova.local: solo actualizaciones dinamicas
#      SEGURAS y sin transferencias de zona.
#   2. Zona inversa 202.168.192.in-addr.arpa (red de las VMs),
#      integrada en AD para que DC02 la reciba sola.
#   3. Reenviadores 8.8.8.8 (Google) y 1.1.1.1 (Cloudflare): dos
#      proveedores distintos para tener redundancia.
#   4. Registros A + PTR fijos de los servidores Linux (no se
#      registran solos en el DNS de Windows).
#   5. (Opcional, -CrearRegistrosServicio) nombres de servicio que
#      apuntan a la VIP .27: www, sftp y sqlag (confirmados 18/11).
#   6. Registro PTR de DC01 y envejecimiento/limpieza (scavenging)
#      de registros dinamicos antiguos.
#   7. Comprobacion final con 93-comprobar-dns.ps1 (si esta en la
#      misma carpeta).
#
# Ejecutar en DC01 con una cuenta de administrador del dominio:
#   powershell -ExecutionPolicy Bypass -File .\04-configurar-dns.ps1
# Con los nombres de servicio:
#   powershell -ExecutionPolicy Bypass -File .\04-configurar-dns.ps1 -CrearRegistrosServicio
#
# No borra nada: si un registro ya existe con otra IP, avisa y no
# lo cambia (para no pisar algo hecho a mano).
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$Zona = "cibernova.local",
    [string]$RedInversa = "192.168.202.0/24",
    [string]$ZonaInversa = "202.168.192.in-addr.arpa",
    [string[]]$Reenviadores = @("8.8.8.8", "1.1.1.1"),
    [string]$IpVip = "192.168.202.27",
    [switch]$CrearRegistrosServicio,
    [switch]$SinScavenging
)

$ErrorActionPreference = "Stop"
Import-Module DnsServer

function Escribir([string]$Estado, [string]$Texto) {
    $color = switch ($Estado) { "OK" {"Green"} "CREADO" {"Cyan"} "AVISO" {"Yellow"} "FALLO" {"Red"} default {"White"} }
    Write-Host ("[{0}] {1}" -f $Estado, $Texto) -ForegroundColor $color
}

# Servidores Linux: no se registran solos -> registros fijos A + PTR
$RegistrosFijos = @(
    @{ Nombre = "lnx01"; IP = "192.168.202.28" },
    @{ Nombre = "lnx02"; IP = "192.168.202.29" },
    @{ Nombre = "bkp01"; IP = "192.168.202.30" },
    @{ Nombre = "bkp02"; IP = "192.168.202.31" }
)

# Nombres de servicio -> VIP de Pacemaker (sin PTR: la .27 no es una maquina)
$RegistrosServicio = @("www", "sftp", "sqlag")

Write-Host "=== CiberNova - Configuracion DNS en $env:COMPUTERNAME ===" -ForegroundColor White

# ----------------------------------------------------------
# 1. ZONA DIRECTA
# ----------------------------------------------------------
$z = Get-DnsServerZone -Name $Zona -ErrorAction SilentlyContinue
if (-not $z) { Escribir "FALLO" "No existe la zona $Zona. Este script se ejecuta en un DC con DNS."; exit 1 }
if (-not $z.IsDsIntegrated) { Escribir "AVISO" "La zona $Zona no esta integrada en AD: DC02 no la recibira por replicacion." }
else { Escribir "OK" "Zona $Zona integrada en AD (replicacion: $($z.ReplicationScope))." }

if ($z.DynamicUpdate -ne "Secure") {
    Set-DnsServerPrimaryZone -Name $Zona -DynamicUpdate Secure
    Escribir "CREADO" "Zona ${Zona}: actualizaciones dinamicas solo seguras."
} else { Escribir "OK" "Zona ${Zona}: actualizaciones dinamicas solo seguras." }

if ($z.SecureSecondaries -ne "NoTransfer") {
    Set-DnsServerPrimaryZone -Name $Zona -SecureSecondaries NoTransfer
    Escribir "CREADO" "Zona ${Zona}: transferencias de zona desactivadas."
} else { Escribir "OK" "Zona ${Zona}: transferencias de zona desactivadas." }

# ----------------------------------------------------------
# 2. ZONA INVERSA
# ----------------------------------------------------------
$zi = Get-DnsServerZone -Name $ZonaInversa -ErrorAction SilentlyContinue
if (-not $zi) {
    Add-DnsServerPrimaryZone -NetworkId $RedInversa -ReplicationScope Domain -DynamicUpdate Secure
    Escribir "CREADO" "Zona inversa $ZonaInversa ($RedInversa), integrada en AD."
} else { Escribir "OK" "Zona inversa $ZonaInversa ya existe." }
$zi = Get-DnsServerZone -Name $ZonaInversa
if ($zi.SecureSecondaries -ne "NoTransfer") {
    Set-DnsServerPrimaryZone -Name $ZonaInversa -SecureSecondaries NoTransfer
    Escribir "CREADO" "Zona ${ZonaInversa}: transferencias de zona desactivadas."
}

# ----------------------------------------------------------
# 3. REENVIADORES
# ----------------------------------------------------------
$actuales = @((Get-DnsServerForwarder).IPAddress | ForEach-Object { $PSItem.IPAddressToString })
foreach ($r in $Reenviadores) {
    if ($actuales -contains $r) { Escribir "OK" "Reenviador $r ya configurado." }
    else { Add-DnsServerForwarder -IPAddress $r; Escribir "CREADO" "Reenviador $r." }
}
foreach ($a in $actuales) {
    if ($Reenviadores -notcontains $a) { Escribir "AVISO" "Hay otro reenviador no previsto: $a (no se toca)." }
}

# ----------------------------------------------------------
# 4. REGISTROS FIJOS DE LOS LINUX (A + PTR)
# ----------------------------------------------------------
function Asegurar-PTR([string]$Nombre, [string]$IP) {
    $ultimo = $IP.Split(".")[3]
    $fqdn = "$Nombre.$Zona."
    $ptr = Get-DnsServerResourceRecord -ZoneName $ZonaInversa -Name $ultimo -RRType Ptr -ErrorAction SilentlyContinue
    if (-not $ptr) {
        Add-DnsServerResourceRecordPtr -ZoneName $ZonaInversa -Name $ultimo -PtrDomainName $fqdn
        Escribir "CREADO" "PTR $IP -> $fqdn"
    } elseif (@($ptr.RecordData.PtrDomainName) -notcontains $fqdn) {
        Escribir "AVISO" "El PTR de $IP apunta a $(@($ptr.RecordData.PtrDomainName) -join ', ') (no se toca)."
    } else { Escribir "OK" "PTR $IP -> $fqdn" }
}

foreach ($reg in $RegistrosFijos) {
    $a = Get-DnsServerResourceRecord -ZoneName $Zona -Name $reg.Nombre -RRType A -ErrorAction SilentlyContinue
    if (-not $a) {
        Add-DnsServerResourceRecordA -ZoneName $Zona -Name $reg.Nombre -IPv4Address $reg.IP
        Escribir "CREADO" "A $($reg.Nombre).$Zona -> $($reg.IP)"
    } elseif (@($a.RecordData.IPv4Address.IPAddressToString) -notcontains $reg.IP) {
        Escribir "AVISO" "$($reg.Nombre).$Zona ya existe con otra IP: $(@($a.RecordData.IPv4Address.IPAddressToString) -join ', ') (no se toca)."
    } else { Escribir "OK" "A $($reg.Nombre).$Zona -> $($reg.IP)" }
    Asegurar-PTR $reg.Nombre $reg.IP
}

# ----------------------------------------------------------
# 5. NOMBRES DE SERVICIO -> VIP (opcional)
# ----------------------------------------------------------
if ($CrearRegistrosServicio) {
    foreach ($n in $RegistrosServicio) {
        $a = Get-DnsServerResourceRecord -ZoneName $Zona -Name $n -RRType A -ErrorAction SilentlyContinue
        if (-not $a) {
            Add-DnsServerResourceRecordA -ZoneName $Zona -Name $n -IPv4Address $IpVip
            Escribir "CREADO" "A $n.$Zona -> $IpVip (VIP)"
        } elseif (@($a.RecordData.IPv4Address.IPAddressToString) -notcontains $IpVip) {
            Escribir "AVISO" "$n.$Zona ya existe con otra IP (no se toca)."
        } else { Escribir "OK" "A $n.$Zona -> $IpVip (VIP)" }
    }
} else {
    Escribir "INFO" "Nombres de servicio (www, sftp, sqlag -> VIP) no creados: usar -CrearRegistrosServicio cuando se confirmen."
}

# ----------------------------------------------------------
# 6. PTR DE DC01 Y SCAVENGING
# ----------------------------------------------------------
Register-DnsClient
Escribir "OK" "Registro DNS del propio servidor renovado (A y PTR dinamicos)."

if (-not $SinScavenging) {
    Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00 -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00 -ApplyOnAllZones
    Set-DnsServerZoneAging -Name $Zona -Aging $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00
    Set-DnsServerZoneAging -Name $ZonaInversa -Aging $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00
    Escribir "OK" "Envejecimiento y limpieza activados (7 + 7 dias; los registros fijos no caducan)."
}

# ----------------------------------------------------------
# 7. COMPROBACION
# ----------------------------------------------------------
$comprobar = Join-Path $PSScriptRoot "93-comprobar-dns.ps1"
if (Test-Path $comprobar) {
    Write-Host ""
    if ($CrearRegistrosServicio) { & $comprobar -ComprobarServicio } else { & $comprobar }
} else {
    Escribir "INFO" "No se encuentra 93-comprobar-dns.ps1 en la carpeta: comprobad a mano."
}
