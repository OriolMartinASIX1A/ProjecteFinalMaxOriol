# ==========================================================
# CIBERNOVA - 94. COMPROBAR LAS GPO DE SEGURIDAD (script 05)
# Dominio: cibernova.local
# Version: 1.0 (18/11/2026)
# ----------------------------------------------------------
# Solo lee, no cambia nada. Muestra OK / FALLO / INFO por prueba
# y guarda un informe HTML de cada GPO (evidencia para la memoria).
# Uso en DC01, despues de "gpupdate /force":
#   powershell -ExecutionPolicy Bypass -File .\94-comprobar-gpo.ps1
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$RutaSysvol = "",
    [string]$CarpetaInformes = "C:\CiberNova\informes-gpo"
)

Import-Module GroupPolicy
Import-Module ActiveDirectory
Import-Module NetSecurity

$script:ok = 0; $script:fallo = 0
function Prueba([string]$Texto, [bool]$Resultado) {
    if ($Resultado) { $script:ok++; Write-Host "[OK]    $Texto" -ForegroundColor Green }
    else { $script:fallo++; Write-Host "[FALLO] $Texto" -ForegroundColor Red }
}
function Info([string]$Texto) { Write-Host "[INFO]  $Texto" -ForegroundColor Yellow }

$Dominio = Get-ADDomain
$DnDominio = $Dominio.DistinguishedName
$Fqdn = $Dominio.DNSRoot
if (-not $RutaSysvol) { $RutaSysvol = "\\$Fqdn\SYSVOL\$Fqdn\Policies" }
$OuEquipos = (Get-ADOrganizationalUnit -Filter 'Name -eq "Equipos"' | Select-Object -First 1).DistinguishedName
$OuServidores = (Get-ADOrganizationalUnit -Filter 'Name -eq "Servidores"' | Select-Object -First 1).DistinguishedName
$SidServicio = (Get-ADGroup -Filter 'Name -eq "G_Cuentas_Servicio"').SID.Value
$SidAdmin = (Get-ADGroup -Filter 'Name -eq "G_Admin_Sistemas"').SID.Value

Write-Host "=== CiberNova - Comprobacion de las GPO de seguridad ===" -ForegroundColor White

function Leer([string]$Ruta) { if (Test-Path $Ruta) { [IO.File]::ReadAllText($Ruta) } else { "" } }

$gpos = [ordered]@{
    "GPO_Dominio_CuentasServicio" = $DnDominio
    "GPO_Equipos_SinCuentasAdm"   = $OuEquipos
    "GPO_Dominio_Firewall"        = $DnDominio
    "GPO_Servidores_Auditoria"    = $OuServidores
}

if (-not (Test-Path $CarpetaInformes)) { New-Item -ItemType Directory -Path $CarpetaInformes -Force | Out-Null }

foreach ($n in $gpos.Keys) {
    Write-Host ""
    $g = Get-GPO -Name $n -ErrorAction SilentlyContinue
    Prueba "$n existe" ([bool]$g)
    if (-not $g) { continue }
    $enlaces = @((Get-GPInheritance -Target $gpos[$n]).GpoLinks | ForEach-Object { $PSItem.DisplayName })
    Prueba "$n vinculada en $($gpos[$n])" ($enlaces -contains $n)
    Prueba "$n tiene configuracion de equipo (version > 0)" ($g.Computer.DSVersion -gt 0)
    $inf = Leer (Join-Path $RutaSysvol "{$($g.Id)}\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf")
    switch ($n) {
        "GPO_Dominio_CuentasServicio" {
            Prueba "Denegar inicio de sesion local a G_Cuentas_Servicio" ($inf -match "SeDenyInteractiveLogonRight\s*=.*$SidServicio")
            Prueba "Denegar inicio de sesion por RDP a G_Cuentas_Servicio" ($inf -match "SeDenyRemoteInteractiveLogonRight\s*=.*$SidServicio")
        }
        "GPO_Equipos_SinCuentasAdm" {
            Prueba "Denegar inicio de sesion local a G_Admin_Sistemas" ($inf -match "SeDenyInteractiveLogonRight\s*=.*$SidAdmin")
            Prueba "Denegar inicio de sesion por RDP a G_Admin_Sistemas" ($inf -match "SeDenyRemoteInteractiveLogonRight\s*=.*$SidAdmin")
        }
        "GPO_Dominio_Firewall" {
            $perfiles = Get-NetFirewallProfile -PolicyStore "$Fqdn\$n"
            foreach ($p in $perfiles) {
                Prueba "Firewall perfil $($p.Name): activado, entrada bloqueada, salida permitida" (("$($p.Enabled)" -eq "True") -and ("$($p.DefaultInboundAction)" -eq "Block") -and ("$($p.DefaultOutboundAction)" -eq "Allow"))
            }
            $r = Get-NetFirewallRule -PolicyStore "$Fqdn\$n" -DisplayName "CiberNova - Ping (ICMPv4 eco de entrada)" -ErrorAction SilentlyContinue
            Prueba "Regla de ping (ICMPv4 eco de entrada)" ([bool]$r)
        }
        "GPO_Servidores_Auditoria" {
            $csv = Leer (Join-Path $RutaSysvol "{$($g.Id)}\Machine\Microsoft\Windows NT\Audit\audit.csv")
            Prueba "Auditar sistema de archivos (correcto y error)" ($csv -match "Audit File System.*Success and Failure")
            Prueba "Auditar inicio de sesion (correcto y error)" ($csv -match "Audit Logon.*Success and Failure")
            Prueba "Forzar subcategorias de auditoria" ($inf -match "SCENoApplyLegacyAuditPolicy=4,1")
        }
    }
    $informe = Join-Path $CarpetaInformes "$n.html"
    Get-GPOReport -Name $n -ReportType Html -Path $informe
    Info "Informe: $informe"
}

# --- Lo que ya se aplica en este DC (GPO vinculadas al dominio) ---
Write-Host ""
$gp = (gpresult /scope computer /r) -join "`n"
Prueba "DC01 aplica GPO_Dominio_CuentasServicio (gpresult)" ($gp -match "GPO_Dominio_CuentasServicio")
Prueba "DC01 aplica GPO_Dominio_Firewall (gpresult)" ($gp -match "GPO_Dominio_Firewall")
$activo = Get-NetFirewallProfile -PolicyStore ActiveStore
Info ("Firewall efectivo en este equipo: " + (($activo | ForEach-Object { "$($PSItem.Name)=$($PSItem.Enabled)" }) -join ", "))
Info "GPO_Equipos_SinCuentasAdm y GPO_Servidores_Auditoria se comprueban en CLI01/CLI02 y FS01/FS02 cuando esten unidos."

Write-Host ""
Write-Host ("Resultado: {0} OK, {1} FALLO" -f $script:ok, $script:fallo) -ForegroundColor White
