# ==========================================================
# CIBERNOVA - 84. DESHACER LA CONFIGURACION DNS DEL SCRIPT 04
# Dominio: cibernova.local
# Version: 1.0 (17/11/2026)
# ----------------------------------------------------------
# Devuelve el DNS de DC01 al estado de despues de crear el dominio,
# para volver a configurarlo paso a paso. Quita SOLO lo anadido:
#   1. Zona inversa 202.168.192.in-addr.arpa (y con ella los PTR).
#   2. Registros A fijos: lnx01, lnx02, bkp01, bkp02 y, si existen,
#      www, sftp y sqlag (solo si apuntan a las IP previstas).
#   3. Envejecimiento y limpieza (scavenging): desactivados.
#   4. Reenviadores (incluido 192.168.200.254, anadido a mano el
#      16/11). Con -ConservarReenviadores no se tocan.
#
# NO toca nada de lo que necesita el dominio para funcionar:
#   - las zonas cibernova.local y _msdcs.cibernova.local,
#   - los registros del DC (A de dc01, SRV, NS, SOA...),
#   - la configuracion "solo actualizaciones seguras" y "sin
#     transferencias" (son los valores por defecto de una zona
#     creada al promocionar el DC; el script los muestra).
#
# Antes de cambiar nada:
#   - exporta las zonas a C:\Windows\System32\dns\ (copia de seguridad),
#   - muestra lo que va a quitar y pide escribir SI.
#
# Uso en DC01 (PowerShell como administrador del dominio):
#   powershell -ExecutionPolicy Bypass -File .\84-deshacer-dns.ps1
#   powershell -ExecutionPolicy Bypass -File .\84-deshacer-dns.ps1 -ConservarReenviadores
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$Zona = "cibernova.local",
    [string]$ZonaInversa = "202.168.192.in-addr.arpa",
    [switch]$ConservarReenviadores
)

$ErrorActionPreference = "Stop"
Import-Module DnsServer

function Escribir([string]$Estado, [string]$Texto) {
    $color = switch ($Estado) { "OK" {"Green"} "QUITADO" {"Cyan"} "AVISO" {"Yellow"} "FALLO" {"Red"} default {"White"} }
    Write-Host ("[{0}] {1}" -f $Estado, $Texto) -ForegroundColor $color
}

# Registros que creo el script 04 (nombre -> IP esperada)
$Registros = [ordered]@{
    "lnx01" = "192.168.202.28"; "lnx02" = "192.168.202.29"
    "bkp01" = "192.168.202.30"; "bkp02" = "192.168.202.31"
    "www"   = "192.168.202.27"; "sftp"  = "192.168.202.27"; "sqlag" = "192.168.202.27"
}

Write-Host "=== CiberNova - Deshacer configuracion DNS en $env:COMPUTERNAME ===" -ForegroundColor White

$z = Get-DnsServerZone -Name $Zona -ErrorAction SilentlyContinue
if (-not $z) { Escribir "FALLO" "No existe la zona $Zona. No se hace nada."; exit 1 }

# ----------------------------------------------------------
# 1. QUE HAY AHORA
# ----------------------------------------------------------
$plan = @()
$zi = Get-DnsServerZone -Name $ZonaInversa -ErrorAction SilentlyContinue
if ($zi) { $plan += "Borrar la zona inversa $ZonaInversa (y sus PTR)" }

$aBorrar = @()
foreach ($n in $Registros.Keys) {
    $r = Get-DnsServerResourceRecord -ZoneName $Zona -Name $n -RRType A -ErrorAction SilentlyContinue
    if ($r) {
        $ips = @($r.RecordData.IPv4Address.IPAddressToString)
        if ($ips -contains $Registros[$n]) { $aBorrar += $n; $plan += "Borrar el registro A $n.$Zona -> $($Registros[$n])" }
        else { Escribir "AVISO" "$n.$Zona apunta a $($ips -join ', ') (no lo creo el script 04): no se toca." }
    }
}

$sc = Get-DnsServerScavenging
if ($sc.ScavengingState) { $plan += "Desactivar el envejecimiento y la limpieza de registros" }

$fw = @((Get-DnsServerForwarder).IPAddress | Where-Object { $PSItem } | ForEach-Object { $PSItem.IPAddressToString })
if (-not $ConservarReenviadores -and $fw.Count -gt 0) { $plan += "Quitar los reenviadores: $($fw -join ', ')" }

Escribir "INFO" "Zona ${Zona}: actualizaciones=$($z.DynamicUpdate), transferencias=$($z.SecureSecondaries) (no se cambian)."

if ($plan.Count -eq 0) { Escribir "OK" "No hay nada que deshacer: el DNS ya esta como despues de crear el dominio."; exit 0 }

Write-Host ""
Write-Host "Se va a hacer lo siguiente:" -ForegroundColor White
$plan | ForEach-Object { Write-Host "  - $PSItem" }
Write-Host ""
$resp = Read-Host "Escribe SI (en mayusculas) para continuar"
if ($resp -cne "SI") { Escribir "INFO" "Cancelado. No se ha cambiado nada."; exit 0 }

# ----------------------------------------------------------
# 2. COPIA DE SEGURIDAD DE LAS ZONAS
# ----------------------------------------------------------
$marca = Get-Date -Format "yyyyMMdd-HHmmss"
foreach ($nz in @($Zona, $ZonaInversa)) {
    if (Get-DnsServerZone -Name $nz -ErrorAction SilentlyContinue) {
        $fich = "copia-$nz-$marca.dns"
        Export-DnsServerZone -Name $nz -FileName $fich
        Escribir "OK" "Copia de la zona $nz en C:\Windows\System32\dns\$fich"
    }
}

# ----------------------------------------------------------
# 3. DESHACER
# ----------------------------------------------------------
if ($zi) {
    Remove-DnsServerZone -Name $ZonaInversa -Force
    Escribir "QUITADO" "Zona inversa $ZonaInversa"
}

foreach ($n in $aBorrar) {
    Remove-DnsServerResourceRecord -ZoneName $Zona -Name $n -RRType A -RecordData $Registros[$n] -Force
    Escribir "QUITADO" "A $n.$Zona -> $($Registros[$n])"
}

if ($sc.ScavengingState) {
    Set-DnsServerScavenging -ScavengingState $false
    foreach ($nz in @($Zona, "_msdcs.$Zona")) {
        if (Get-DnsServerZone -Name $nz -ErrorAction SilentlyContinue) { Set-DnsServerZoneAging -Name $nz -Aging $false }
    }
    Escribir "QUITADO" "Envejecimiento y limpieza de registros"
}

if (-not $ConservarReenviadores) {
    foreach ($ip in $fw) {
        Remove-DnsServerForwarder -IPAddress $ip -Force
        Escribir "QUITADO" "Reenviador $ip"
    }
}

# ----------------------------------------------------------
# 4. COMPROBAR QUE EL DOMINIO SIGUE BIEN
# ----------------------------------------------------------
Write-Host ""
$srv = $null
try { $srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Zona" -Type SRV -Server 127.0.0.1 -DnsOnly -ErrorAction Stop | Where-Object { $PSItem.Type -eq "SRV" } } catch {}
if ($srv) { Escribir "OK" "El dominio sigue localizable (SRV _ldap._tcp.dc._msdcs.$Zona)." }
else { Escribir "FALLO" "No se encuentra el SRV del dominio. Ejecutar: Restart-Service Netlogon; ipconfig /registerdns" }

$a = $null
try { $a = Resolve-DnsName -Name "$($env:COMPUTERNAME).$Zona" -Type A -Server 127.0.0.1 -DnsOnly -ErrorAction Stop } catch {}
if ($a) { Escribir "OK" "$($env:COMPUTERNAME).$Zona resuelve." } else { Escribir "FALLO" "$($env:COMPUTERNAME).$Zona no resuelve. Ejecutar: ipconfig /registerdns" }

Write-Host ""
Escribir "INFO" "Listo. Para volver a configurar: 04-configurar-dns.ps1 (entero) o paso a paso."
