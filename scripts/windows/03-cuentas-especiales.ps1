# ==========================================================
# CIBERNOVA - 03. CUENTAS ESPECIALES (Anexo I, apartado 5)
# Dominio: cibernova.local
# Version: 1.0 (16/11/2026)
# ----------------------------------------------------------
# Requisito: haber ejecutado antes 01 y 02.
# Ejecutar en DC01 con una cuenta de administrador del dominio:
#   powershell -ExecutionPolicy Bypass -File .\03-cuentas-especiales.ps1
#
# Cuando se sepa la fecha de fin de la Fase 3, volver a ejecutarlo asi:
#   powershell -ExecutionPolicy Bypass -File .\03-cuentas-especiales.ps1 -CaducidadAuditor "2027-06-15"
#
# Idempotente: si una cuenta ya existe, no la vuelve a crear ni le
# cambia la contrasena; solo corrige sus restricciones y grupos.
# auditor.ext se crea DESHABILITADA y el script nunca la vuelve a
# deshabilitar: cuando el profesorado lo indique se habilita a mano.
#
# Las contrasenas se guardan cifradas (DPAPI) en el mismo almacen que
# el script 02: C:\CiberNova-Privado\CredencialesIniciales.xml
# Fichero 100% ASCII a proposito (ver bitacora 16/11/2026).
# ==========================================================

param(
    [string]$EquipoRecepcion = "BCN-RECEPCION",
    [Nullable[datetime]]$CaducidadAuditor = $null,
    [string]$RutaPrivada = "C:\CiberNova-Privado",
    [switch]$SinPermisosNTFS   # solo para pruebas fuera de Windows
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

# ----------------------------------------------------------
# 1. CONFIGURACION
# ----------------------------------------------------------

$NombreOUEspeciales = "Cuentas especiales"

$Dominio = Get-ADDomain
$DN = $Dominio.DistinguishedName

$OUPrincipal  = "OU=CiberNova,$DN"
$OUGrupos     = "OU=Grupos,$OUPrincipal"
$OUEspeciales = "OU=$NombreOUEspeciales,$OUPrincipal"
$OUServicios  = "OU=Servicios,$OUEspeciales"

$RutaCredenciales = Join-Path $RutaPrivada "CredencialesIniciales.xml"
$RutaLogs = Join-Path $RutaPrivada "logs"

# Grupos globales para estas cuentas (modelo AGDLP: los permisos de
# carpeta se daran a los grupos DL_ en los que se aniden estos grupos).
$GruposEspeciales = @(
    @{Nombre="G_Recepcion";        Descripcion="Cuenta compartida de recepcion (consulta de Comun)"},
    @{Nombre="G_Auditor_Externo";  Descripcion="Auditoria externa (Fase 3): consulta de Sistemas\Documentacion y Legal\Comite_Seguridad"},
    @{Nombre="G_Cuentas_Servicio"; Descripcion="Cuentas de servicio: sin inicio de sesion interactivo (GPO)"}
)

$CuentasServicio = @(
    @{Sam="svc_backup"; Descripcion="Servicio de copias (Bareos). Lectura de toda la estructura de carpetas. Sin inicio de sesion interactivo."},
    @{Sam="svc_web";    Descripcion="Servicio web (Apache). Minimo privilegio. Sin inicio de sesion interactivo."},
    @{Sam="svc_bbdd";   Descripcion="Servicio de base de datos (SQL Server). Minimo privilegio. Sin inicio de sesion interactivo."},
    @{Sam="svc_ia";     Descripcion="Reservada Fase 2 (IA). Solo lectura de logs. Sin acceso a datos de negocio."}
)

# ----------------------------------------------------------
# 2. ALMACEN PRIVADO Y REGISTRO
# ----------------------------------------------------------

foreach ($Ruta in @($RutaPrivada, $RutaLogs)) {
    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item -ItemType Directory -Path $Ruta | Out-Null
    }
}

if (-not $SinPermisosNTFS) {
    $CuentaActual = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    & icacls.exe $RutaPrivada /grant:r `
        "${CuentaActual}:(OI)(CI)F" `
        "*S-1-5-18:(OI)(CI)F" `
        "*S-1-5-32-544:(OI)(CI)F" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudieron conceder permisos en $RutaPrivada" }

    & icacls.exe $RutaPrivada /inheritance:r | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo quitar la herencia en $RutaPrivada" }
}

$RutaTranscript = Join-Path $RutaLogs ("cuentas_especiales_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Start-Transcript -LiteralPath $RutaTranscript | Out-Null

try {

Write-Host "`nDOMINIO: $($Dominio.DNSRoot)" -ForegroundColor Cyan

# ----------------------------------------------------------
# 3. COMPROBACIONES PREVIAS
# ----------------------------------------------------------

Write-Host "`n===== COMPROBACIONES PREVIAS =====" -ForegroundColor Cyan

$Faltan = @()
foreach ($OU in @($OUPrincipal, $OUGrupos, $OUEspeciales, $OUServicios)) {
    $Existe = Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$OU)" -ErrorAction SilentlyContinue
    if (-not $Existe) { $Faltan += "OU: $OU" }
}

if ($Faltan.Count -gt 0) {
    $Faltan | ForEach-Object { Write-Host "  FALTA -> $_" -ForegroundColor Red }
    throw "Faltan OU. Ejecuta primero 01-crear-ou-grupos.ps1"
}

if ($EquipoRecepcion -notmatch '^[A-Za-z0-9-]{1,15}$') {
    throw "Nombre de equipo de recepcion no valido (max. 15 caracteres, letras, numeros y guiones): $EquipoRecepcion"
}

Write-Host "OU correctas." -ForegroundColor Green

# ----------------------------------------------------------
# 4. FUNCIONES DE APOYO
# ----------------------------------------------------------

$RNG = [System.Security.Cryptography.RandomNumberGenerator]::Create()

function Obtener-IndiceAleatorio {
    param([int]$Maximo)
    $Bytes = New-Object byte[] 4
    $RNG.GetBytes($Bytes)
    return [int]([BitConverter]::ToUInt32($Bytes, 0) % [uint32]$Maximo)
}

function Obtener-CaracterAleatorio {
    param([string]$Caracteres)
    return [string]$Caracteres[(Obtener-IndiceAleatorio $Caracteres.Length)]
}

function Generar-Contrasena {
    param([int]$Longitud = 20, [string[]]$Prohibidas = @())

    $Mayusculas = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $Minusculas = "abcdefghijkmnopqrstuvwxyz"
    $Numeros    = "23456789"
    $Especiales = '!@#$%*-_+'
    $Todos      = $Mayusculas + $Minusculas + $Numeros + $Especiales

    while ($true) {
        $Lista = New-Object System.Collections.Generic.List[char]
        $Lista.Add([char](Obtener-CaracterAleatorio $Mayusculas))
        $Lista.Add([char](Obtener-CaracterAleatorio $Minusculas))
        $Lista.Add([char](Obtener-CaracterAleatorio $Numeros))
        $Lista.Add([char](Obtener-CaracterAleatorio $Especiales))
        while ($Lista.Count -lt $Longitud) {
            $Lista.Add([char](Obtener-CaracterAleatorio $Todos))
        }
        for ($i = $Lista.Count - 1; $i -gt 0; $i--) {
            $j = Obtener-IndiceAleatorio ($i + 1)
            $Temporal = $Lista[$i]; $Lista[$i] = $Lista[$j]; $Lista[$j] = $Temporal
        }
        $Contrasena = -join $Lista.ToArray()

        $Valida = $true
        foreach ($Palabra in $Prohibidas) {
            if ($Palabra.Length -ge 3 -and
                $Contrasena.ToLowerInvariant().Contains($Palabra.ToLowerInvariant())) {
                $Valida = $false; break
            }
        }
        if ($Valida) { return $Contrasena }
    }
}

$Credenciales = New-Object System.Collections.Generic.List[object]
if (Test-Path -LiteralPath $RutaCredenciales) {
    foreach ($CredencialAnterior in @(Import-Clixml -LiteralPath $RutaCredenciales)) {
        $Credenciales.Add($CredencialAnterior)
    }
}

function Registrar-Credencial {
    param([string]$Usuario, [string]$Contrasena)
    $Secure = ConvertTo-SecureString $Contrasena -AsPlainText -Force
    $Credenciales.Add((New-Object System.Management.Automation.PSCredential($Usuario, $Secure)))
    $Credenciales.ToArray() | Export-Clixml -LiteralPath $RutaCredenciales -Force
}

function Crear-GrupoSiFalta {
    param([string]$Nombre, [string]$Descripcion)
    $Existe = Get-ADGroup -Filter "SamAccountName -eq '$Nombre'" -ErrorAction SilentlyContinue
    if (-not $Existe) {
        New-ADGroup -Name $Nombre -SamAccountName $Nombre -GroupCategory Security `
            -GroupScope Global -Path $OUGrupos -Description $Descripcion
        Write-Host "Grupo creado: $Nombre" -ForegroundColor Green
    }
    else {
        Write-Host "Grupo existente: $Nombre" -ForegroundColor Yellow
    }
}

function Agregar-A-Grupo {
    param([string]$Sam, [string]$NombreGrupo)
    $Grupo = Get-ADGroup -Identity $NombreGrupo
    $Usuario = Get-ADUser -Identity $Sam -Properties MemberOf
    if (@($Usuario.MemberOf) -notcontains $Grupo.DistinguishedName) {
        Add-ADGroupMember -Identity $Grupo -Members $Usuario
        Write-Host "  + $NombreGrupo"
    }
}

# Crea la cuenta si no existe (con contrasena aleatoria) y devuelve $true si es nueva.
function Crear-CuentaSiFalta {
    param(
        [string]$Sam,
        [string]$NombreMostrar,
        [string]$Descripcion,
        [string]$Ruta,
        [int]$Longitud,
        [bool]$Habilitada,
        [bool]$CambiarEnPrimerInicio
    )

    $Existe = Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue
    if ($Existe) {
        Write-Host "Cuenta existente: $Sam (no se cambia su contrasena)" -ForegroundColor Yellow
        return $false
    }

    $Contrasena = Generar-Contrasena -Longitud $Longitud `
        -Prohibidas (@($Sam) + ($Sam -split '[\._]') + ($NombreMostrar -split '[\s\.,\-_#]+'))

    New-ADUser `
        -Name $NombreMostrar `
        -DisplayName $NombreMostrar `
        -SamAccountName $Sam `
        -UserPrincipalName "$Sam@$($Dominio.DNSRoot)" `
        -Description $Descripcion `
        -Path $Ruta `
        -AccountPassword (ConvertTo-SecureString $Contrasena -AsPlainText -Force) `
        -Enabled $Habilitada `
        -ChangePasswordAtLogon $CambiarEnPrimerInicio

    Registrar-Credencial -Usuario $Sam -Contrasena $Contrasena
    Write-Host "Cuenta creada: $Sam" -ForegroundColor Green
    return $true
}

# logonHours: 21 bytes desde el domingo 00:00 UTC; en cada byte el bit menos
# significativo es la primera hora. Se calcula con la zona horaria del servidor.
function Obtener-Horario {
    param([int]$HoraInicio, [int]$HoraFin)

    $Zona = [System.TimeZoneInfo]::Local
    $HoyUTC = [DateTime]::SpecifyKind([DateTime]::UtcNow.Date, [DateTimeKind]::Utc)
    $DomingoUTC = $HoyUTC.AddDays(-[int]$HoyUTC.DayOfWeek)
    $BytesHorario = New-Object byte[] 21

    for ($i = 0; $i -lt 168; $i++) {
        $HoraLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($DomingoUTC.AddHours($i), $Zona)
        $DiaLaborable = $HoraLocal.DayOfWeek -notin @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)
        if ($DiaLaborable -and $HoraLocal.Hour -ge $HoraInicio -and $HoraLocal.Hour -lt $HoraFin) {
            $BytesHorario[[int][math]::Floor($i / 8)] = $BytesHorario[[int][math]::Floor($i / 8)] -bor (1 -shl ($i % 8))
        }
    }
    return ,$BytesHorario
}

# ----------------------------------------------------------
# 5. GRUPOS DE LAS CUENTAS ESPECIALES
# ----------------------------------------------------------

Write-Host "`n===== GRUPOS =====" -ForegroundColor Cyan

foreach ($Grupo in $GruposEspeciales) {
    Crear-GrupoSiFalta -Nombre $Grupo.Nombre -Descripcion $Grupo.Descripcion
}

# ----------------------------------------------------------
# 6. recepcion.bcn (cuenta compartida)
# ----------------------------------------------------------

Write-Host "`n===== recepcion.bcn =====" -ForegroundColor Cyan

Crear-CuentaSiFalta `
    -Sam "recepcion.bcn" `
    -NombreMostrar "Recepcion Barcelona" `
    -Descripcion "Cuenta compartida del puesto de recepcion de Barcelona. Solo inicia sesion en $EquipoRecepcion. Perfil obligatorio. Sin carpeta personal." `
    -Ruta $OUEspeciales `
    -Longitud 16 `
    -Habilitada $true `
    -CambiarEnPrimerInicio $false | Out-Null

# - Solo puede iniciar sesion en el equipo de recepcion (userWorkstations).
# - No puede cambiar su contrasena; como no puede cambiarla, no caduca
#   (si caducara, la cuenta quedaria bloqueada). Sistemas la cambia segun
#   el procedimiento documentado en la memoria tecnica.
Set-ADUser -Identity "recepcion.bcn" `
    -LogonWorkstations $EquipoRecepcion `
    -CannotChangePassword $true `
    -PasswordNeverExpires $true `
    -Office "Barcelona"

Agregar-A-Grupo -Sam "recepcion.bcn" -NombreGrupo "G_Recepcion"
# NO se anade a G_Sede_Barcelona: ese grupo podra modificar Comun\Sedes\Barcelona
# (P-43) y recepcion solo puede consultar Comun (P-44).

Write-Host "  Restricciones: solo $EquipoRecepcion, no puede cambiar la contrasena." -ForegroundColor Cyan

# ----------------------------------------------------------
# 7. auditor.ext (externa temporal)
# ----------------------------------------------------------

Write-Host "`n===== auditor.ext =====" -ForegroundColor Cyan

# Se crea deshabilitada. Si ya existe, NO se toca su estado (el profesorado
# indicara cuando habilitarla).
Crear-CuentaSiFalta `
    -Sam "auditor.ext" `
    -NombreMostrar "Auditor Externo" `
    -Descripcion "Auditoria independiente (Fase 3). Se habilita cuando lo indique el profesorado. Horario L-V 8:00-20:00." `
    -Ruta $OUEspeciales `
    -Longitud 20 `
    -Habilitada $false `
    -CambiarEnPrimerInicio $true | Out-Null

Set-ADUser -Identity "auditor.ext" -Replace @{ logonHours = [byte[]](Obtener-Horario -HoraInicio 8 -HoraFin 20) }

if ($CaducidadAuditor) {
    $Fin = ([datetime]$CaducidadAuditor).Date.AddDays(1).AddSeconds(-1)   # hasta las 23:59:59 de ese dia
    Set-ADAccountExpiration -Identity "auditor.ext" -DateTime $Fin
    Write-Host "  Caducidad: $($Fin.ToString('dd/MM/yyyy HH:mm'))" -ForegroundColor Cyan
}
else {
    Write-Host "  Caducidad: PENDIENTE (fin de la Fase 3). Volver a ejecutar con -CaducidadAuditor AAAA-MM-DD" -ForegroundColor Magenta
}

Agregar-A-Grupo -Sam "auditor.ext" -NombreGrupo "G_Auditor_Externo"

$EstadoAuditor = (Get-ADUser -Identity "auditor.ext").Enabled
Write-Host "  Horario L-V 8:00-20:00. Habilitada: $EstadoAuditor" -ForegroundColor Cyan

# ----------------------------------------------------------
# 8. CUENTAS DE SERVICIO (svc_*)
# ----------------------------------------------------------

Write-Host "`n===== CUENTAS DE SERVICIO =====" -ForegroundColor Cyan

foreach ($Servicio in $CuentasServicio) {

    Crear-CuentaSiFalta `
        -Sam $Servicio.Sam `
        -NombreMostrar $Servicio.Sam `
        -Descripcion $Servicio.Descripcion `
        -Ruta $OUServicios `
        -Longitud 32 `
        -Habilitada $true `
        -CambiarEnPrimerInicio $false | Out-Null

    # Contrasena de 32 caracteres que no caduca ni puede cambiar la propia
    # cuenta: la rota Sistemas segun el procedimiento documentado.
    Set-ADUser -Identity $Servicio.Sam `
        -CannotChangePassword $true `
        -PasswordNeverExpires $true

    Agregar-A-Grupo -Sam $Servicio.Sam -NombreGrupo "G_Cuentas_Servicio"
}

# ----------------------------------------------------------
# 9. RESUMEN
# ----------------------------------------------------------

Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan

Get-ADUser -Filter * -SearchBase $OUEspeciales -SearchScope Subtree `
    -Properties CannotChangePassword,PasswordNeverExpires,LogonWorkstations,AccountExpirationDate,Description |
    Where-Object { $_.SamAccountName -notlike "adm.*" } |
    Sort-Object SamAccountName |
    Select-Object SamAccountName,Enabled,CannotChangePassword,PasswordNeverExpires,LogonWorkstations,AccountExpirationDate |
    Format-Table -AutoSize

Write-Host "PENDIENTE (otras fases del proyecto):" -ForegroundColor Magenta
Write-Host "  - GPO: denegar inicio de sesion local y por RDP a G_Cuentas_Servicio."
Write-Host "  - GPO: privilegio 'Hacer copias de seguridad' para svc_backup en los servidores de ficheros."
Write-Host "  - recepcion.bcn: perfil obligatorio y crear el equipo $EquipoRecepcion en el dominio."
Write-Host "  - Permisos de carpeta (DL_) para G_Recepcion y G_Auditor_Externo."
if (-not $CaducidadAuditor) { Write-Host "  - Caducidad de auditor.ext (fin de la Fase 3)." }

Write-Host "`nArchivo cifrado de credenciales: $RutaCredenciales"
Write-Host "Registro de esta ejecucion:      $RutaTranscript"
Write-Host "`nCUENTAS ESPECIALES FINALIZADAS" -ForegroundColor Green

}
finally {
    if ($RNG) { $RNG.Dispose() }
    Stop-Transcript | Out-Null
}
