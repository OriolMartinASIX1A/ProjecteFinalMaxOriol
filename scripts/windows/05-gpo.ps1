# ==========================================================
# CIBERNOVA - 05. DIRECTIVAS DE GRUPO (GPO) DE SEGURIDAD
# Dominio: cibernova.local
# Version: 1.1 (18/11/2026)
# Cambios 1.1: Get-NetFirewallRule no admite -GPOSession; la regla de
#   ping se busca con -PolicyStore (fallo en la primera ejecucion en DC01).
# ----------------------------------------------------------
# Crea y vincula 4 GPO (todo idempotente: se puede ejecutar varias
# veces; si algo ya esta bien, no lo toca):
#
#  1. GPO_Dominio_CuentasServicio  (vinculada al dominio)
#     Denegar inicio de sesion local y por Escritorio remoto a
#     G_Cuentas_Servicio (Anexo I, ap. 5: svc_* sin inicio de
#     sesion interactivo).
#  2. GPO_Equipos_SinCuentasAdm    (vinculada a la OU Equipos)
#     Denegar inicio de sesion local y por Escritorio remoto a
#     G_Admin_Sistemas en los equipos de usuarios (Anexo I, ap. 5:
#     las cuentas adm. no inician sesion en equipos de usuarios).
#  3. GPO_Dominio_Firewall         (vinculada al dominio)
#     Firewall de Windows activado en los 3 perfiles, entrada
#     bloqueada salvo reglas, salida permitida, reglas locales
#     respetadas (las crean los roles: AD, DNS, DFS...) y regla de
#     ping (ICMPv4 eco) para las pruebas. Compensa la red plana.
#  4. GPO_Servidores_Auditoria     (vinculada a la OU Servidores)
#     Auditoria avanzada: sistema de archivos e inicio de sesion
#     (correcto y error) + forzar subcategorias. Base para P-11,
#     P-39 y la prueba 15 (las carpetas se marcan con FS01/FS02).
#
# Requisitos: DC01 con los modulos GroupPolicy, ActiveDirectory y
# NetSecurity (vienen con el rol de controlador de dominio). OU
# Equipos y Servidores (script 01) y grupos G_Cuentas_Servicio
# (script 03) y G_Admin_Sistemas (script 02).
#
# Uso en DC01 (PowerShell como administrador del dominio):
#   cd C:\CiberNova
#   powershell -ExecutionPolicy Bypass -File .\05-gpo.ps1
# Despues: gpupdate /force y 94-comprobar-gpo.ps1 (capturas).
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$RutaSysvol = ""      # vacio = \\<dominio>\SYSVOL\<dominio>\Policies
)

$ErrorActionPreference = "Stop"
Import-Module GroupPolicy
Import-Module ActiveDirectory
Import-Module NetSecurity

function Escribir([string]$Estado, [string]$Texto) {
    $color = switch ($Estado) { "OK" {"Green"} "CREADO" {"Cyan"} "AVISO" {"Yellow"} "FALLO" {"Red"} default {"White"} }
    Write-Host ("[{0}] {1}" -f $Estado, $Texto) -ForegroundColor $color
}

$Dominio = Get-ADDomain
$DnDominio = $Dominio.DistinguishedName
$FqdnDominio = $Dominio.DNSRoot
if (-not $RutaSysvol) { $RutaSysvol = "\\$FqdnDominio\SYSVOL\$FqdnDominio\Policies" }

# Extensiones de cliente (CSE) que tiene que anunciar cada GPO
$CseSeguridad = "[{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}]"
$CseAuditoria = "[{F3CCC681-B74C-4060-9F26-CD84525DCA2A}{0F3F3735-573D-9804-99E4-AB2A69BA5FD4}]"

Write-Host "=== CiberNova - GPO de seguridad en $env:COMPUTERNAME ===" -ForegroundColor White

# ----------------------------------------------------------
# 0. COMPROBACIONES PREVIAS
# ----------------------------------------------------------
$OuEquipos = Get-ADOrganizationalUnit -Filter 'Name -eq "Equipos"' | Select-Object -First 1
$OuServidores = Get-ADOrganizationalUnit -Filter 'Name -eq "Servidores"' | Select-Object -First 1
$GrpServicio = Get-ADGroup -Filter 'Name -eq "G_Cuentas_Servicio"'
$GrpAdmin = Get-ADGroup -Filter 'Name -eq "G_Admin_Sistemas"'
$falta = @()
if (-not $OuEquipos) { $falta += "OU Equipos (script 01)" }
if (-not $OuServidores) { $falta += "OU Servidores (script 01)" }
if (-not $GrpServicio) { $falta += "Grupo G_Cuentas_Servicio (script 03)" }
if (-not $GrpAdmin) { $falta += "Grupo G_Admin_Sistemas (script 02)" }
if ($falta.Count -gt 0) { $falta | ForEach-Object { Escribir "FALLO" "Falta: $PSItem" }; exit 1 }
Escribir "OK" "OU Equipos, OU Servidores, G_Cuentas_Servicio y G_Admin_Sistemas encontrados."

$miembrosAdmin = @(Get-ADGroupMember -Identity $GrpAdmin | ForEach-Object { $PSItem.SamAccountName })
$noAdm = @($miembrosAdmin | Where-Object { $PSItem -notlike "adm.*" })
if ($noAdm.Count -gt 0) {
    Escribir "FALLO" "G_Admin_Sistemas contiene cuentas que no son adm.: $($noAdm -join ', '). No podrian entrar en los equipos de usuarios. Revisar antes de seguir."
    exit 1
}
Escribir "OK" "G_Admin_Sistemas solo tiene cuentas adm. ($($miembrosAdmin.Count))."

# ----------------------------------------------------------
# FUNCIONES AUXILIARES
# ----------------------------------------------------------
function Asegurar-GPO([string]$Nombre, [string]$Comentario, [string]$Destino) {
    $g = Get-GPO -Name $Nombre -ErrorAction SilentlyContinue
    if (-not $g) {
        $g = New-GPO -Name $Nombre -Comment $Comentario
        Escribir "CREADO" "GPO $Nombre"
        Start-Sleep -Seconds 2
    } else { Escribir "OK" "GPO $Nombre ya existe." }
    $enlaces = @((Get-GPInheritance -Target $Destino).GpoLinks | ForEach-Object { $PSItem.DisplayName })
    if ($enlaces -notcontains $Nombre) {
        New-GPLink -Name $Nombre -Target $Destino -LinkEnabled Yes | Out-Null
        Escribir "CREADO" "Vinculo de $Nombre en $Destino"
    } else { Escribir "OK" "$Nombre ya vinculada en $Destino" }
    return $g
}

# Sube la version de la parte de equipo de la GPO (AD + GPT.INI) y
# anade las extensiones de cliente necesarias. Sin esto, los equipos
# no se enteran de que la GPO ha cambiado.
function Actualizar-VersionGPO($Gpo, [string[]]$Cses) {
    $dnGpo = "CN={$($Gpo.Id)},CN=Policies,CN=System,$DnDominio"
    $obj = Get-ADObject -Identity $dnGpo -Properties versionNumber, gPCMachineExtensionNames
    $ver = [int]$obj.versionNumber
    $nueva = ($ver -band 0xFFFF0000) + (($ver -band 0xFFFF) + 1)
    $ext = [string]$obj.gPCMachineExtensionNames
    foreach ($c in $Cses) { if (-not $ext.Contains($c)) { $ext += $c } }
    # Las extensiones deben ir ordenadas por GUID
    $lista = @([regex]::Matches($ext, '\[[^\]]+\]') | ForEach-Object { $PSItem.Value } | Sort-Object -Unique)
    $ext = $lista -join ""
    Set-ADObject -Identity $dnGpo -Replace @{ versionNumber = $nueva; gPCMachineExtensionNames = $ext }
    $ini = Join-Path $RutaSysvol "{$($Gpo.Id)}\GPT.INI"
    $texto = if (Test-Path $ini) { [IO.File]::ReadAllText($ini) } else { "[General]`r`nVersion=0`r`n" }
    if ($texto -match 'Version=\d+') { $texto = $texto -replace 'Version=\d+', "Version=$nueva" }
    else { $texto = $texto.TrimEnd() + "`r`nVersion=$nueva`r`n" }
    [IO.File]::WriteAllText($ini, $texto, [Text.Encoding]::ASCII)
}

# Escribe un fichero de la GPO solo si su contenido cambia.
# Devuelve $true si lo ha cambiado.
function Escribir-Fichero([string]$Ruta, [string]$Contenido, $Codificacion) {
    $dir = Split-Path $Ruta -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $Ruta) {
        $actual = [IO.File]::ReadAllText($Ruta)
        if ($actual.Trim() -eq $Contenido.Trim()) { return $false }
    }
    [IO.File]::WriteAllText($Ruta, $Contenido, $Codificacion)
    return $true
}

function Plantilla-Seguridad([string]$Derechos, [string]$Registro) {
    $t = "[Unicode]`r`nUnicode=yes`r`n[Version]`r`nsignature=`"`$CHICAGO`$`"`r`nRevision=1`r`n"
    if ($Derechos) { $t += "[Privilege Rights]`r`n$Derechos`r`n" }
    if ($Registro) { $t += "[Registry Values]`r`n$Registro`r`n" }
    return $t
}

function Ruta-Inf($Gpo) { Join-Path $RutaSysvol "{$($Gpo.Id)}\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf" }

# ----------------------------------------------------------
# 1. CUENTAS DE SERVICIO SIN INICIO DE SESION (dominio)
# ----------------------------------------------------------
Write-Host ""
$g1 = Asegurar-GPO "GPO_Dominio_CuentasServicio" "Anexo I ap. 5: svc_* sin inicio de sesion interactivo (local ni RDP)." $DnDominio
$sid = "*" + $GrpServicio.SID.Value
$inf = Plantilla-Seguridad "SeDenyInteractiveLogonRight = $sid`r`nSeDenyRemoteInteractiveLogonRight = $sid" ""
if (Escribir-Fichero (Ruta-Inf $g1) $inf ([Text.Encoding]::Unicode)) {
    Actualizar-VersionGPO $g1 @($CseSeguridad)
    Escribir "CREADO" "Denegar inicio de sesion local y por RDP a G_Cuentas_Servicio"
} else { Escribir "OK" "Derechos de G_Cuentas_Servicio ya configurados." }

# ----------------------------------------------------------
# 2. CUENTAS ADM. FUERA DE LOS EQUIPOS DE USUARIOS (OU Equipos)
# ----------------------------------------------------------
Write-Host ""
$g2 = Asegurar-GPO "GPO_Equipos_SinCuentasAdm" "Anexo I ap. 5: las cuentas adm. no inician sesion en equipos de usuarios." $OuEquipos.DistinguishedName
$sid = "*" + $GrpAdmin.SID.Value
$inf = Plantilla-Seguridad "SeDenyInteractiveLogonRight = $sid`r`nSeDenyRemoteInteractiveLogonRight = $sid" ""
if (Escribir-Fichero (Ruta-Inf $g2) $inf ([Text.Encoding]::Unicode)) {
    Actualizar-VersionGPO $g2 @($CseSeguridad)
    Escribir "CREADO" "Denegar inicio de sesion local y por RDP a G_Admin_Sistemas en Equipos"
} else { Escribir "OK" "Derechos de G_Admin_Sistemas en Equipos ya configurados." }

# ----------------------------------------------------------
# 3. FIREWALL DE WINDOWS (dominio)
# ----------------------------------------------------------
Write-Host ""
$g3 = Asegurar-GPO "GPO_Dominio_Firewall" "Firewall de Windows activado en todos los perfiles (compensa la red plana, diseno 3.11)." $DnDominio
$almacen = "$FqdnDominio\GPO_Dominio_Firewall"
$sesion = Open-NetGPO -PolicyStore $almacen
Set-NetFirewallProfile -GPOSession $sesion -Profile Domain, Private, Public -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -AllowLocalFirewallRules True
Escribir "OK" "Perfiles dominio, privado y publico: activado, entrada bloqueada, salida permitida, reglas locales respetadas."
$regla = Get-NetFirewallRule -PolicyStore $almacen -DisplayName "CiberNova - Ping (ICMPv4 eco de entrada)" -ErrorAction SilentlyContinue
if (-not $regla) {
    New-NetFirewallRule -GPOSession $sesion -DisplayName "CiberNova - Ping (ICMPv4 eco de entrada)" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow -Profile Any | Out-Null
    Escribir "CREADO" "Regla de ping (ICMPv4 eco de entrada)"
} else { Escribir "OK" "Regla de ping ya existe." }
Save-NetGPO -GPOSession $sesion
Escribir "OK" "Configuracion de firewall guardada en la GPO."

# ----------------------------------------------------------
# 4. AUDITORIA AVANZADA (OU Servidores)
# ----------------------------------------------------------
Write-Host ""
$g4 = Asegurar-GPO "GPO_Servidores_Auditoria" "Auditoria de acceso a archivos e inicio de sesion (P-11, P-39, prueba 15)." $OuServidores.DistinguishedName
$csv = "Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting,Setting Value`r`n" +
       ",System,Audit File System,{0cce921d-69ae-11d9-bed3-505054503030},Success and Failure,,3`r`n" +
       ",System,Audit Logon,{0cce9215-69ae-11d9-bed3-505054503030},Success and Failure,,3`r`n"
$rutaCsv = Join-Path $RutaSysvol "{$($g4.Id)}\Machine\Microsoft\Windows NT\Audit\audit.csv"
$c1 = Escribir-Fichero $rutaCsv $csv ([Text.Encoding]::ASCII)
# Opcion de seguridad: forzar subcategorias (si no, Windows puede ignorar la auditoria avanzada)
$inf = Plantilla-Seguridad "" "MACHINE\System\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy=4,1"
$c2 = Escribir-Fichero (Ruta-Inf $g4) $inf ([Text.Encoding]::Unicode)
if ($c1 -or $c2) {
    Actualizar-VersionGPO $g4 @($CseSeguridad, $CseAuditoria)
    Escribir "CREADO" "Auditar sistema de archivos e inicio de sesion (correcto y error) + forzar subcategorias"
} else { Escribir "OK" "Auditoria avanzada ya configurada." }

# ----------------------------------------------------------
# 5. SIGUIENTE PASO
# ----------------------------------------------------------
Write-Host ""
Escribir "INFO" "Hecho. Ahora: gpupdate /force y despues 94-comprobar-gpo.ps1 (capturas)."
Escribir "INFO" "GPO_Equipos_SinCuentasAdm y GPO_Servidores_Auditoria se aplicaran cuando haya equipos en esas OU."
