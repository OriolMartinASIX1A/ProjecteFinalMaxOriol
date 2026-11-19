# ==========================================================
# CIBERNOVA - 93. COMPROBAR EL DNS
# Dominio: cibernova.local
# Version: 1.2 (19/11/2026)
# Cambios 1.2: comprueba los reenviadores 8.8.8.8 y 1.1.1.1 (los
#   configurados de verdad en DC01; la v1.1 decia 1.1.1.1 y 9.9.9.9).
# Cambios 1.1: comprueba los reenviadores 1.1.1.1 y 9.9.9.9.
# ----------------------------------------------------------
# Solo lee, no cambia nada. Muestra OK / FALLO / INFO por prueba.
# Uso en DC01:
#   powershell -ExecutionPolicy Bypass -File .\93-comprobar-dns.ps1
# Para comprobar que DC02 tiene lo mismo (cuando exista):
#   powershell -ExecutionPolicy Bypass -File .\93-comprobar-dns.ps1 -Servidor 192.168.202.24
# Si ya se crearon los nombres de servicio (www, sftp, sqlag):
#   ... -ComprobarServicio
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$Servidor = "127.0.0.1",
    [string]$Zona = "cibernova.local",
    [string]$ZonaInversa = "202.168.192.in-addr.arpa",
    [string[]]$Reenviadores = @("8.8.8.8", "1.1.1.1"),
    [string]$IpVip = "192.168.202.27",
    [switch]$ComprobarServicio
)

$script:ok = 0; $script:fallo = 0

function Prueba([string]$Texto, [bool]$Resultado) {
    if ($Resultado) { $script:ok++; Write-Host "[OK]    $Texto" -ForegroundColor Green }
    else { $script:fallo++; Write-Host "[FALLO] $Texto" -ForegroundColor Red }
}
function Info([string]$Texto) { Write-Host "[INFO]  $Texto" -ForegroundColor Yellow }

function IPs-A([string]$Nombre) {
    try { @(Resolve-DnsName -Name $Nombre -Type A -Server $Servidor -DnsOnly -ErrorAction Stop | Where-Object { $PSItem.Type -eq "A" } | ForEach-Object { $PSItem.IPAddress }) }
    catch { @() }
}
function Nombre-PTR([string]$IP) {
    try { @(Resolve-DnsName -Name $IP -Type PTR -Server $Servidor -DnsOnly -ErrorAction Stop | Where-Object { $PSItem.Type -eq "PTR" } | ForEach-Object { $PSItem.NameHost.TrimEnd(".").ToLower() }) }
    catch { @() }
}

Write-Host "=== CiberNova - Comprobacion DNS (servidor consultado: $Servidor) ===" -ForegroundColor White

# --- Configuracion del servidor DNS ---
$equipo = if ($Servidor -eq "127.0.0.1") { $env:COMPUTERNAME } else { $Servidor }
try {
    $z = Get-DnsServerZone -Name $Zona -ComputerName $equipo -ErrorAction Stop
    Prueba "Zona $Zona integrada en AD" ([bool]$z.IsDsIntegrated)
    Prueba "Zona $Zona solo con actualizaciones seguras" ($z.DynamicUpdate -eq "Secure")
    Prueba "Zona $Zona sin transferencias de zona" ($z.SecureSecondaries -eq "NoTransfer")
    $zi = Get-DnsServerZone -Name $ZonaInversa -ComputerName $equipo -ErrorAction SilentlyContinue
    Prueba "Zona inversa $ZonaInversa existe" ([bool]$zi)
    if ($zi) { Prueba "Zona inversa integrada en AD" ([bool]$zi.IsDsIntegrated) }
    $fw = @((Get-DnsServerForwarder -ComputerName $equipo).IPAddress | ForEach-Object { $PSItem.IPAddressToString })
    foreach ($r in $Reenviadores) { Prueba "Reenviador $r configurado" ($fw -contains $r) }
    $sc = Get-DnsServerScavenging -ComputerName $equipo
    Info "Limpieza (scavenging): $($sc.ScavengingState), cada $($sc.ScavengingInterval)"
} catch {
    Info "No se pudo leer la configuracion del servidor DNS ($($PSItem.Exception.Message)). Se comprueba solo la resolucion."
}

# --- Registros del dominio ---
$srv = $null
try { $srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Zona" -Type SRV -Server $Servidor -DnsOnly -ErrorAction Stop | Where-Object { $PSItem.Type -eq "SRV" } } catch {}
Prueba "SRV _ldap._tcp.dc._msdcs.$Zona (localizar los DC)" ([bool]$srv)
if ($srv) { Info ("DC anunciados: " + ((@($srv) | ForEach-Object { $PSItem.NameTarget }) -join ", ")) }

Prueba "dc01.$Zona -> 192.168.202.23" ((IPs-A "dc01.$Zona") -contains "192.168.202.23")
Prueba "PTR 192.168.202.23 -> dc01.$Zona" ((Nombre-PTR "192.168.202.23") -contains "dc01.$Zona")

$dc02 = IPs-A "dc02.$Zona"
if ($dc02.Count -gt 0) { Prueba "dc02.$Zona -> 192.168.202.24" ($dc02 -contains "192.168.202.24") }
else { Info "dc02.$Zona aun no existe (normal hasta promocionar DC02)." }

$fijos = [ordered]@{ "lnx01" = "192.168.202.28"; "lnx02" = "192.168.202.29"; "bkp01" = "192.168.202.30"; "bkp02" = "192.168.202.31" }
foreach ($n in $fijos.Keys) {
    Prueba "$n.$Zona -> $($fijos[$n])" ((IPs-A "$n.$Zona") -contains $fijos[$n])
    Prueba "PTR $($fijos[$n]) -> $n.$Zona" ((Nombre-PTR $fijos[$n]) -contains "$n.$Zona")
}

if ($ComprobarServicio) {
    foreach ($n in @("www", "sftp", "sqlag")) { Prueba "$n.$Zona -> $IpVip (VIP)" ((IPs-A "$n.$Zona") -contains $IpVip) }
}

# --- Resolucion externa (depende de la red del aula) ---
$ext = IPs-A "www.google.com"
if ($ext.Count -gt 0) { Prueba "Resolucion externa (www.google.com) via reenviador" $true }
else { Info "No resuelve www.google.com: revisar los reenviadores ($($Reenviadores -join ', '))." }

# --- DNS configurado en la tarjeta de este equipo ---
$dnsLocal = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $PSItem.ServerAddresses } | ForEach-Object { "$($PSItem.InterfaceAlias): $($PSItem.ServerAddresses -join ', ')" }) -join " | "
Info "DNS de las tarjetas de este equipo: $dnsLocal"

Write-Host ""
Write-Host ("Resultado: {0} OK, {1} FALLO" -f $script:ok, $script:fallo) -ForegroundColor White
