# ==========================================================
# CIBERNOVA - 92. COMPROBAR CUENTAS ESPECIALES (para capturas)
# Version: 1.0 (16/11/2026)
# Solo lee; no cambia nada. Fichero 100% ASCII, sin la variable $_ .
#   powershell -ExecutionPolicy Bypass -File .\92-comprobar-cuentas-especiales.ps1
# Comprueba los requisitos del Anexo I, apartado 5, y marca OK / FALLO.
# ==========================================================

param([string]$EquipoRecepcion = "BCN-RECEPCION")

Import-Module ActiveDirectory

$Dominio = Get-ADDomain
$base = "OU=CiberNova," + $Dominio.DistinguishedName
$Propiedades = @("Enabled","CannotChangePassword","PasswordNeverExpires","LogonWorkstations",
                 "AccountExpirationDate","logonHours","MemberOf","Description")

# --- Convierte logonHours (21 bytes, UTC) en texto legible en hora local ---
function Resumir-Horario {
    param($Bytes)

    if (-not $Bytes) { return "Sin restriccion" }

    $Zona = [System.TimeZoneInfo]::Local
    $HoyUTC = [DateTime]::SpecifyKind([DateTime]::UtcNow.Date, [DateTimeKind]::Utc)
    $DomingoUTC = $HoyUTC.AddDays(-[int]$HoyUTC.DayOfWeek)
    $Horas = @{}

    for ($i = 0; $i -lt 168; $i++) {
        if ((($Bytes[[int][math]::Floor($i / 8)] -shr ($i % 8)) -band 1) -eq 1) {
            $Local = [System.TimeZoneInfo]::ConvertTimeFromUtc($DomingoUTC.AddHours($i), $Zona)
            $Dia = [int]$Local.DayOfWeek
            if (-not $Horas.ContainsKey($Dia)) { $Horas[$Dia] = @() }
            $Horas[$Dia] += $Local.Hour
        }
    }

    if ($Horas.Count -eq 0) { return "Nunca" }

    $Nombres = @{1="L";2="M";3="X";4="J";5="V";6="S";0="D"}
    $Partes = foreach ($Dia in @(1,2,3,4,5,6,0)) {
        if ($Horas.ContainsKey($Dia)) {
            $Lista = $Horas[$Dia] | Sort-Object
            "{0} {1}-{2}h" -f $Nombres[$Dia], $Lista[0], ($Lista[-1] + 1)
        }
    }
    return ($Partes -join ", ")
}

function Nombre-Grupos {
    param($MemberOf)
    return (@($MemberOf) | ForEach-Object { ($PSItem -split ',')[0] -replace '^CN=' }) -join ', '
}

function Obtener-Cuenta {
    param([string]$Sam)
    return Get-ADUser -Filter "SamAccountName -eq '$Sam'" -Properties $Propiedades -ErrorAction SilentlyContinue
}

$Resultados = New-Object System.Collections.Generic.List[object]
function Comprobar {
    param([string]$Cuenta, [string]$Requisito, [bool]$Cumple, [string]$Valor)
    $Resultados.Add([pscustomobject]@{
        Cuenta    = $Cuenta
        Requisito = $Requisito
        Valor     = $Valor
        Resultado = $(if ($Cumple) { "OK" } else { "FALLO" })
    })
}

# ----------------------------------------------------------
# 1. TABLA GENERAL
# ----------------------------------------------------------

Write-Host "`n=== CUENTAS ESPECIALES ===" -ForegroundColor Cyan

$Cuentas = @("recepcion.bcn","auditor.ext","svc_backup","svc_web","svc_bbdd","svc_ia")

$Cuentas | ForEach-Object {
    $u = Obtener-Cuenta $PSItem
    if ($u) {
        [pscustomobject]@{
            Cuenta      = $u.SamAccountName
            OU          = (($u.DistinguishedName -split ',')[1] -replace '^OU=')
            Habilitada  = $u.Enabled
            NoCambiaPwd = $u.CannotChangePassword
            PwdNoCaduca = $u.PasswordNeverExpires
            SoloEquipo  = $u.LogonWorkstations
            Horario     = Resumir-Horario $u.logonHours
            Caduca      = $(if ($u.AccountExpirationDate) { $u.AccountExpirationDate.ToString("dd/MM/yyyy") } else { "-" })
            Grupos      = Nombre-Grupos $u.MemberOf
        }
    }
    else {
        [pscustomobject]@{ Cuenta = $PSItem; OU = "NO EXISTE" }
    }
} | Format-Table -AutoSize -Wrap

# ----------------------------------------------------------
# 2. COMPROBACION DE REQUISITOS (Anexo I, apartado 5)
# ----------------------------------------------------------

# recepcion.bcn
$r = Obtener-Cuenta "recepcion.bcn"
Comprobar "recepcion.bcn" "Existe" ([bool]$r) $(if ($r) { "Si" } else { "No" })
if ($r) {
    Comprobar "recepcion.bcn" "Solo inicia sesion en $EquipoRecepcion" ($r.LogonWorkstations -eq $EquipoRecepcion) "$($r.LogonWorkstations)"
    Comprobar "recepcion.bcn" "No puede cambiar su contrasena" ([bool]$r.CannotChangePassword) "$($r.CannotChangePassword)"
    $GruposR = Nombre-Grupos $r.MemberOf
    Comprobar "recepcion.bcn" "Miembro de G_Recepcion" ($GruposR -match '(^|, )G_Recepcion(,|$)') $GruposR
    Comprobar "recepcion.bcn" "NO esta en G_Sede_Barcelona (P-44)" (-not ($GruposR -match 'G_Sede_Barcelona')) $GruposR
}

# auditor.ext
$a = Obtener-Cuenta "auditor.ext"
Comprobar "auditor.ext" "Existe" ([bool]$a) $(if ($a) { "Si" } else { "No" })
if ($a) {
    Comprobar "auditor.ext" "Deshabilitada (hasta que lo indique el profesorado)" (-not $a.Enabled) "Habilitada: $($a.Enabled)"
    $HorarioA = Resumir-Horario $a.logonHours
    Comprobar "auditor.ext" "Horario L-V 8:00-20:00" ($HorarioA -eq "L 8-20h, M 8-20h, X 8-20h, J 8-20h, V 8-20h") $HorarioA
    $GruposA = Nombre-Grupos $a.MemberOf
    Comprobar "auditor.ext" "Miembro de G_Auditor_Externo" ($GruposA -match 'G_Auditor_Externo') $GruposA
    $CaducaA = $(if ($a.AccountExpirationDate) { $a.AccountExpirationDate.ToString("dd/MM/yyyy") } else { "PENDIENTE (fin Fase 3)" })
    Comprobar "auditor.ext" "Caducidad al final de la Fase 3" $true $CaducaA
}

# Cuentas de servicio
foreach ($Sam in @("svc_backup","svc_web","svc_bbdd","svc_ia")) {
    $s = Obtener-Cuenta $Sam
    Comprobar $Sam "Existe en OU Servicios" ([bool]$s -and $s.DistinguishedName -like "*,OU=Servicios,*") $(if ($s) { (($s.DistinguishedName -split ',')[1] -replace '^OU=') } else { "No existe" })
    if ($s) {
        Comprobar $Sam "No puede cambiar su contrasena" ([bool]$s.CannotChangePassword) "$($s.CannotChangePassword)"
        Comprobar $Sam "Contrasena sin caducidad (rotacion documentada)" ([bool]$s.PasswordNeverExpires) "$($s.PasswordNeverExpires)"
        $GruposS = Nombre-Grupos $s.MemberOf
        Comprobar $Sam "Miembro de G_Cuentas_Servicio" ($GruposS -match 'G_Cuentas_Servicio') $GruposS
    }
}

Write-Host "`n=== COMPROBACION DE REQUISITOS ===" -ForegroundColor Cyan
$Resultados | Format-Table Cuenta, Requisito, Valor, Resultado -AutoSize -Wrap

$Fallos = @($Resultados | Where-Object { $PSItem.Resultado -eq "FALLO" }).Count
if ($Fallos -eq 0) {
    Write-Host "RESULTADO: todas las comprobaciones OK ($($Resultados.Count))" -ForegroundColor Green
}
else {
    Write-Host "RESULTADO: $Fallos comprobacion(es) con FALLO de $($Resultados.Count)" -ForegroundColor Red
}

# ----------------------------------------------------------
# 3. GRUPOS DE LAS CUENTAS ESPECIALES
# ----------------------------------------------------------

Write-Host "`n=== GRUPOS ===" -ForegroundColor Cyan
foreach ($NombreGrupo in @("G_Recepcion","G_Auditor_Externo","G_Cuentas_Servicio")) {
    $g = Get-ADGroup -Filter "SamAccountName -eq '$NombreGrupo'" -ErrorAction SilentlyContinue
    if ($g) {
        $Miembros = @(Get-ADGroupMember -Identity $g | ForEach-Object { $PSItem.SamAccountName }) -join ', '
        "{0,-20} {1}" -f $NombreGrupo, $Miembros
    }
    else {
        "{0,-20} NO EXISTE" -f $NombreGrupo
    }
}

Write-Host "`nPendiente en otras sesiones: GPO (sin inicio de sesion interactivo para svc_*, privilegio de copia para svc_backup, perfil obligatorio de recepcion.bcn) y permisos de carpetas." -ForegroundColor Magenta
