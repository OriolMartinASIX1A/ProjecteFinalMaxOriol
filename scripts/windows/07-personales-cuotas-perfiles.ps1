# ==========================================================
# CIBERNOVA - 07. CARPETAS PERSONALES, CUOTAS Y PERFILES MOVILES
# Anexo I, apartado 7 (tareas FS-12, FS-13 y GPO-01)
# Dominio: cibernova.local
# Version: 1.0 (26/11/2026)
# ----------------------------------------------------------
# En FS01 (completo):
#   1. Carpeta personal D:\datos\Personales\<usuario> para cada empleado del
#      CSV (89). Permisos: solo el usuario con Modificar; SYSTEM y
#      Administradores control total (acceso tecnico de Sistemas y copias);
#      DERECHOS DE PROPIETARIO solo leer permisos (no puede cambiarlos).
#      Nadie mas: ni su responsable ni Direccion. ABE oculta las de los demas.
#   2. En AD: unidad H: = \\cibernova.local\empresa\Personales\<usuario>
#      (HomeDrive/HomeDirectory) y, para los perfiles "Movil" del CSV
#      (Direccion y Comercial), ProfilePath = \\cibernova.local\empresa\Perfiles\<usuario>.
#   3. Carpeta D:\datos\Perfiles y recurso oculto Perfiles$ (perfiles moviles),
#      con los permisos que recomienda Microsoft.
#   4. Cuotas FSRM por usuario segun la columna CuotaPersonal del CSV
#      (2GB / 5GB / 500MB), limite estricto y aviso al 90 % (evento en el
#      registro de Aplicacion de FS01).
# En FS02 (-SoloCuotas): solo el punto 4 (las cuotas no se replican con DFS-R).
#
# Idempotente: lo que ya existe se revisa y se deja como dice el plan.
#
# Uso (PowerShell como administrador; CSV en la misma carpeta que el script):
#   FS01: powershell -ExecutionPolicy Bypass -File .\07-personales-cuotas-perfiles.ps1 -Simular
#   FS01: powershell -ExecutionPolicy Bypass -File .\07-personales-cuotas-perfiles.ps1
#   FS02: powershell -ExecutionPolicy Bypass -File .\07-personales-cuotas-perfiles.ps1 -SoloCuotas
#
# Nota: en este script ninguna variable se diferencia de otra solo por
# mayusculas (PowerShell no las distingue; ver incidencia del script 06).
# ==========================================================

param(
    [switch]$Simular,
    [switch]$SoloCuotas,
    [string]$RutaCsv = (Join-Path $PSScriptRoot "usuarios_cibernova.csv"),
    [string]$Servidor = "DC01.cibernova.local"
)

$ErrorActionPreference = "Stop"
function Escribir([string]$Tipo, [string]$Texto) {
    $Color = @{ "OK"="Green"; "NUEVO"="Cyan"; "AVISO"="Yellow"; "ERROR"="Red"; "SIM"="Magenta"; "INFO"="Gray" }[$Tipo]
    Write-Host ("[{0}] {1}" -f $Tipo, $Texto) -ForegroundColor $Color
}

if (@("FS01","FS02") -notcontains $env:COMPUTERNAME) { Escribir "ERROR" "Ejecutar en FS01 (o en FS02 con -SoloCuotas)."; exit 1 }
if ($env:COMPUTERNAME -eq "FS02" -and -not $SoloCuotas) { Escribir "ERROR" "En FS02 solo se ejecuta con -SoloCuotas."; exit 1 }
if (-not (Test-Path -LiteralPath $RutaCsv)) { Escribir "ERROR" "No encuentro el CSV: $RutaCsv (copialo junto al script)."; exit 1 }
if (-not (Get-Module -ListAvailable -Name FileServerResourceManager)) { Escribir "ERROR" "Falta el rol FSRM (Administrador de recursos del servidor de archivos)."; exit 1 }
Import-Module FileServerResourceManager
if ($Simular) { Escribir "SIM" "MODO SIMULACION: no se cambia nada." }

$Empleados = @(Import-Csv -LiteralPath $RutaCsv -Delimiter ';' -Encoding UTF8)
Escribir "INFO" "$($Empleados.Count) empleados en el CSV."

$RaizPersonales = (Get-SmbShare -Name 'Personales$').Path
$RaizDatos      = Split-Path $RaizPersonales -Parent
$RutaDfs        = "\\cibernova.local\empresa"

# ----------------------------------------------------------
# Tipos y SID
# ----------------------------------------------------------
$Hereda  = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
$NoHereda = [System.Security.AccessControl.InheritanceFlags]::None
$SidSystem      = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-18"
$SidAdmins      = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-32-544"
$SidOwnerRights = New-Object System.Security.Principal.SecurityIdentifier "S-1-3-4"
$SidCreator     = New-Object System.Security.Principal.SecurityIdentifier "S-1-3-0"
$SidAutentif    = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-11"

function Nueva-Regla(
    [System.Security.Principal.SecurityIdentifier]$Sid,
    [System.Security.AccessControl.FileSystemRights]$Derechos,
    [System.Security.AccessControl.InheritanceFlags]$Herencia,
    [System.Security.AccessControl.PropagationFlags]$Propagacion = [System.Security.AccessControl.PropagationFlags]::None
) {
    return [System.Security.AccessControl.FileSystemAccessRule]::new($Sid, $Derechos, $Herencia, $Propagacion, [System.Security.AccessControl.AccessControlType]::Allow)
}

function Poner-Acl([string]$Ruta, $Reglas) {
    $carpeta = Get-Item -LiteralPath $Ruta
    $acl = $carpeta.GetAccessControl('Access')
    foreach ($vieja in @($acl.Access | Where-Object { -not $_.IsInherited })) { [void]$acl.RemoveAccessRuleSpecific($vieja) }
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($regla in $Reglas) { $acl.AddAccessRule($regla) }
    $carpeta.SetAccessControl($acl)
}

function Tamano-Cuota([string]$Texto) {
    switch ($Texto.Trim().ToUpper()) {
        "2GB"   { return 2GB }
        "5GB"   { return 5GB }
        "500MB" { return 500MB }
        default { throw "Cuota desconocida en el CSV: '$Texto'" }
    }
}

if (-not $SoloCuotas) {
    Import-Module ActiveDirectory

    # ------------------------------------------------------
    # 1 y 2. CARPETAS PERSONALES Y ATRIBUTOS DE AD
    # ------------------------------------------------------
    Write-Host "`n===== 1. CARPETAS PERSONALES Y UNIDAD H: =====" -ForegroundColor Cyan
    $Hechas = 0
    foreach ($emp in $Empleados) {
        $usu  = $emp.Usuario.Trim()
        $cuenta = Get-ADUser -Server $Servidor -Filter "SamAccountName -eq '$usu'" -ErrorAction SilentlyContinue
        if (-not $cuenta) { Escribir "AVISO" "$usu no existe en AD (se salta)"; continue }
        $dirPersonal = Join-Path $RaizPersonales $usu
        $unc = "$RutaDfs\Personales\$usu"
        $perfil = if ($emp.Perfil.Trim() -eq "Movil") { "$RutaDfs\Perfiles\$usu" } else { $null }
        if ($Simular) {
            Escribir "SIM" ("{0}  H:={1}{2}" -f $dirPersonal, $unc, $(if ($perfil) { "  Perfil movil=$perfil" } else { "" }))
            continue
        }
        if (-not (Test-Path -LiteralPath $dirPersonal)) { New-Item -ItemType Directory -Path $dirPersonal | Out-Null }
        Poner-Acl $dirPersonal @(
            (Nueva-Regla $SidSystem      ([System.Security.AccessControl.FileSystemRights]::FullControl) $Hereda),
            (Nueva-Regla $SidAdmins      ([System.Security.AccessControl.FileSystemRights]::FullControl) $Hereda),
            (Nueva-Regla $SidOwnerRights ([System.Security.AccessControl.FileSystemRights]::ReadPermissions) $Hereda),
            (Nueva-Regla $cuenta.SID     ([System.Security.AccessControl.FileSystemRights]'Modify, Synchronize') $Hereda)
        )
        if ($perfil) {
            Set-ADUser -Server $Servidor -Identity $cuenta -HomeDrive "H:" -HomeDirectory $unc -ProfilePath $perfil
        } else {
            Set-ADUser -Server $Servidor -Identity $cuenta -HomeDrive "H:" -HomeDirectory $unc -Clear ProfilePath
        }
        $Hechas++
    }
    if (-not $Simular) { Escribir "OK" "$Hechas carpetas personales con permisos y unidad H: en AD." }

    # ------------------------------------------------------
    # 3. PERFILES MOVILES: D:\datos\Perfiles y Perfiles$
    # ------------------------------------------------------
    Write-Host "`n===== 2. PERFILES MOVILES (Perfiles`$) =====" -ForegroundColor Cyan
    $dirPerfiles = Join-Path $RaizDatos "Perfiles"
    if ($Simular) {
        Escribir "SIM" "Crearia $dirPerfiles y el recurso Perfiles`$ (ABE, Usuarios autentificados en SMB)"
    } else {
        if (-not (Test-Path -LiteralPath $dirPerfiles)) { New-Item -ItemType Directory -Path $dirPerfiles | Out-Null; Escribir "NUEVO" "Carpeta $dirPerfiles" }
        # Permisos recomendados por Microsoft para la raiz de perfiles moviles:
        # cada usuario solo puede crear SU carpeta (la crea Windows al iniciar sesion)
        # y no ve las de los demas; CREATOR OWNER control total solo dentro de la suya.
        Poner-Acl $dirPerfiles @(
            (Nueva-Regla $SidSystem   ([System.Security.AccessControl.FileSystemRights]::FullControl) $Hereda),
            (Nueva-Regla $SidAdmins   ([System.Security.AccessControl.FileSystemRights]::FullControl) $Hereda),
            (Nueva-Regla $SidAutentif ([System.Security.AccessControl.FileSystemRights]'ListDirectory, ReadAttributes, ReadPermissions, CreateDirectories, Traverse, Synchronize') $NoHereda),
            (Nueva-Regla $SidCreator  ([System.Security.AccessControl.FileSystemRights]::FullControl) $Hereda ([System.Security.AccessControl.PropagationFlags]::InheritOnly))
        )
        if (-not (Get-SmbShare -Name 'Perfiles$' -ErrorAction SilentlyContinue)) {
            $nombreAutentif = $SidAutentif.Translate([System.Security.Principal.NTAccount]).Value
            New-SmbShare -Name 'Perfiles$' -Path $dirPerfiles -FullAccess $nombreAutentif -FolderEnumerationMode AccessBased -CachingMode None | Out-Null
            Escribir "NUEVO" "Recurso compartido Perfiles`$ (sin cache sin conexion, como pide Microsoft para perfiles)"
        }
        Escribir "OK" "Perfiles`$ preparado. Falta anadirlo al espacio de nombres DFS (ver guia)."
    }
}

# ----------------------------------------------------------
# 4. CUOTAS FSRM
# ----------------------------------------------------------
Write-Host "`n===== 3. CUOTAS FSRM =====" -ForegroundColor Cyan
$Plantillas = @{ "2GB" = "CiberNova personal 2 GB"; "5GB" = "CiberNova personal 5 GB"; "500MB" = "CiberNova personal 500 MB" }
foreach ($clave in $Plantillas.Keys) {
    $nombre = $Plantillas[$clave]
    if (Get-FsrmQuotaTemplate -Name $nombre -ErrorAction SilentlyContinue) { continue }
    if ($Simular) { Escribir "SIM" "Crearia la plantilla '$nombre' (limite estricto, aviso al 90 %)"; continue }
    $accion = New-FsrmAction -Type Event -EventType Warning -Body "CiberNova: el usuario [Source Io Owner] ha llegado al [Quota Threshold]% de su cuota en [Quota Path] ([Quota Used MB] MB de [Quota Limit MB] MB)."
    $umbral = New-FsrmQuotaThreshold -Percentage 90 -Action $accion
    New-FsrmQuotaTemplate -Name $nombre -Size (Tamano-Cuota $clave) -Threshold $umbral | Out-Null
    Escribir "NUEVO" "Plantilla de cuota: $nombre"
}
$Cuotas = 0; $SinCarpeta = 0
foreach ($emp in $Empleados) {
    $usu = $emp.Usuario.Trim()
    $dirPersonal = Join-Path $RaizPersonales $usu
    $plantilla = $Plantillas[$emp.CuotaPersonal.Trim().ToUpper()]
    if (-not $plantilla) { Escribir "ERROR" "$usu tiene una cuota desconocida en el CSV: $($emp.CuotaPersonal)"; continue }
    if ($Simular) { Escribir "SIM" "Cuota '$plantilla' en $dirPersonal"; continue }
    if (-not (Test-Path -LiteralPath $dirPersonal)) { $SinCarpeta++; continue }
    $actual = Get-FsrmQuota -Path $dirPersonal -ErrorAction SilentlyContinue
    if ($actual -and $actual.Template -eq $plantilla) { $Cuotas++; continue }
    if ($actual) { Remove-FsrmQuota -Path $dirPersonal -Confirm:$false }
    New-FsrmQuota -Path $dirPersonal -Template $plantilla | Out-Null
    $Cuotas++
}
if (-not $Simular) {
    Escribir "OK" "$Cuotas cuotas aplicadas."
    if ($SinCarpeta -gt 0) { Escribir "AVISO" "$SinCarpeta carpetas personales aun no existen aqui (en FS02: espera a que DFS-R las replique y repite)." }
}

Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
if ($Simular) { Escribir "SIM" "Simulacion terminada." }
else { Escribir "OK" "Terminado en $env:COMPUTERNAME. Comprobar: Get-FsrmQuota | Select-Object Path, Size, Template | Format-Table -AutoSize" }
