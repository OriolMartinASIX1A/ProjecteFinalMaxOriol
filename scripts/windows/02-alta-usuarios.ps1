# ==========================================================
# CIBERNOVA - 02. ALTA DE EMPLEADOS Y CUENTAS ADMINISTRATIVAS
# Dominio: cibernova.local
# Version: 2.2 (16/11/2026)
# ----------------------------------------------------------
# Requisito: haber ejecutado antes 01-crear-ou-grupos.ps1
# Ejecutar en DC01 con una cuenta de administrador del dominio:
#   powershell -ExecutionPolicy Bypass -File .\02-alta-usuarios.ps1
#
# Idempotente: se puede ejecutar varias veces. Si una cuenta ya
# existe no la vuelve a crear ni le cambia la contrasena; solo
# completa o corrige sus grupos y restricciones.
#
# Las contrasenas iniciales NUNCA se muestran ni se suben al
# repositorio: se guardan cifradas (DPAPI) en C:\CiberNova-Privado.
# Para consultarlas (solo la misma cuenta, en el mismo equipo):
#   $c = Import-Clixml C:\CiberNova-Privado\CredencialesIniciales.xml
#   ($c | Where-Object UserName -eq 'usuario').GetNetworkCredential().Password
# ----------------------------------------------------------
# Cambios respecto a la version 1 (ver docs/fase1/03-memoria-tecnica.md):
#  - Set-ADUser no tiene el parametro -LogonHours: ahora se usa
#    -Replace @{logonHours = ...}.
#  - Orden de bits del horario corregido (el bit menos significativo
#    de cada byte es la primera hora).
#  - Ruta de la OU "Cuentas especiales" corregida (con espacio).
#  - Comprobacion previa de OU y grupos, con mensaje claro si falta algo.
#  - Las contrasenas generadas no contienen el usuario ni partes del
#    nombre (requisito de complejidad de Windows).
#  - Los becarios se sacan del grupo de su departamento si estuvieran.
#  - G_Admin_Sistemas se anade a Admins. del dominio (por SID, porque el
#    nombre del grupo cambia segun el idioma de Windows).
#  - Registro (transcript) de cada ejecucion en C:\CiberNova-Privado\logs.
#  - (v2.2) Crea G_Politica_15 y G_Admin_Sistemas si faltan, para no
#    depender de la version del script 01.
#  - Fichero 100% ASCII (v2.1): sin tildes ni guiones largos en el codigo.
#    Con un caracter como el guion largo, Windows PowerShell 5.1 leia mal
#    el fichero sin BOM y daba "Token inesperado" / "Falta el terminador".
# ==========================================================

param(
    [string]$RutaCsv = "C:\CiberNova\usuarios_cibernova.csv",
    [string]$RutaPrivada = "C:\CiberNova-Privado",
    [switch]$SinPermisosNTFS   # solo para pruebas fuera de Windows
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

# ----------------------------------------------------------
# 1. CONFIGURACION GENERAL
# ----------------------------------------------------------

$NombreOUEspeciales = "Cuentas especiales"
$TotalEmpleados = 89
$FechaFinBecarios = [datetime]::new(2027, 6, 30, 23, 59, 59)

$Dominio = Get-ADDomain
$DN = $Dominio.DistinguishedName

$OUPrincipal = "OU=CiberNova,$DN"
$OUUsuarios  = "OU=Usuarios,$OUPrincipal"
$OUGrupos    = "OU=Grupos,$OUPrincipal"
$OUAdmins    = "OU=Administracion,OU=$NombreOUEspeciales,$OUPrincipal"

$RutaCredenciales = Join-Path $RutaPrivada "CredencialesIniciales.xml"
$RutaLogs = Join-Path $RutaPrivada "logs"

$Administradores = @(
    @{Empleado="miguel.torres";  Cuenta="adm.miguel.torres"},
    @{Empleado="laia.ribas";     Cuenta="adm.laia.ribas"},
    @{Empleado="fernando.lara";  Cuenta="adm.fernando.lara"},
    @{Empleado="angel.ibanez";   Cuenta="adm.angel.ibanez"},
    @{Empleado="sofia.bermudez"; Cuenta="adm.sofia.bermudez"},
    @{Empleado="inaki.arrieta";  Cuenta="adm.inaki.arrieta"}
)

# ----------------------------------------------------------
# 2. ALMACEN PRIVADO (credenciales y registros)
# ----------------------------------------------------------

foreach ($Ruta in @($RutaPrivada, $RutaLogs)) {
    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item -ItemType Directory -Path $Ruta | Out-Null
    }
}

if (-not $SinPermisosNTFS) {
    $CuentaActual = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Se concede primero y despues se quita la herencia, para no perder el acceso.
    & icacls.exe $RutaPrivada /grant:r `
        "${CuentaActual}:(OI)(CI)F" `
        "*S-1-5-18:(OI)(CI)F" `
        "*S-1-5-32-544:(OI)(CI)F" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudieron conceder permisos en $RutaPrivada"
    }

    & icacls.exe $RutaPrivada /inheritance:r | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo quitar la herencia en $RutaPrivada"
    }
}

$RutaTranscript = Join-Path $RutaLogs ("alta_usuarios_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Start-Transcript -LiteralPath $RutaTranscript | Out-Null

try {

Write-Host "`nDOMINIO: $($Dominio.DNSRoot)" -ForegroundColor Cyan

# ----------------------------------------------------------
# 3. COMPROBACIONES PREVIAS (OU y grupos del script 01)
# ----------------------------------------------------------

Write-Host "`n===== COMPROBACIONES PREVIAS =====" -ForegroundColor Cyan

$OUNecesarias = @($OUPrincipal, $OUUsuarios, $OUGrupos, $OUAdmins)
foreach ($Depto in @("Direccion","Administracion","RRHH","Comercial","Marketing",
                     "Consultoria","Desarrollo","Sistemas","Soporte","Legal")) {
    $OUNecesarias += "OU=$Depto,$OUUsuarios"
}

$GruposNecesarios = @(
    "G_Direccion","G_Administracion","G_RRHH","G_Comercial","G_Marketing",
    "G_Consultoria","G_Desarrollo","G_Sistemas","G_Soporte","G_Legal",
    "G_Sede_Barcelona","G_Sede_Madrid","G_Sede_Valencia",
    "G_Responsables","G_Comite_Seguridad","G_RRHH_Nominas",
    "G_Proyecto_Sanitario","G_Proyecto_Financiero",
    "G_Becarios","G_Becarios_Desarrollo","G_Becarios_Marketing","G_Becarios_Soporte"
)

# Grupos de politica: los usa solo este script, asi que si faltan los crea el
# mismo (v2.2). Asi funciona aunque el script 01 sea una version anterior.
$GruposPolitica = @(
    @{Nombre="G_Politica_15";    Descripcion="Cuentas sujetas a contrasenas de minimo 15 caracteres"},
    @{Nombre="G_Admin_Sistemas"; Descripcion="Cuentas administrativas separadas del uso diario"}
)

$Faltan = @()

foreach ($OU in $OUNecesarias) {
    $Existe = Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$OU)" -ErrorAction SilentlyContinue
    if (-not $Existe) { $Faltan += "OU: $OU" }
}

if ($Faltan -notcontains "OU: $OUGrupos") {
    foreach ($GrupoPolitica in $GruposPolitica) {
        $Existe = Get-ADGroup -Filter "SamAccountName -eq '$($GrupoPolitica.Nombre)'" -ErrorAction SilentlyContinue
        if (-not $Existe) {
            New-ADGroup `
                -Name $GrupoPolitica.Nombre `
                -SamAccountName $GrupoPolitica.Nombre `
                -GroupCategory Security `
                -GroupScope Global `
                -Path $OUGrupos `
                -Description $GrupoPolitica.Descripcion
            Write-Host "Grupo creado: $($GrupoPolitica.Nombre)" -ForegroundColor Green
        }
    }
}

foreach ($NombreGrupo in $GruposNecesarios) {
    $Existe = Get-ADGroup -Filter "SamAccountName -eq '$NombreGrupo'" -ErrorAction SilentlyContinue
    if (-not $Existe) { $Faltan += "Grupo: $NombreGrupo" }
}

if ($Faltan.Count -gt 0) {
    $Faltan | ForEach-Object { Write-Host "  FALTA -> $_" -ForegroundColor Red }
    throw "Faltan OU o grupos. Ejecuta primero 01-crear-ou-grupos.ps1"
}

Write-Host "OU y grupos correctos." -ForegroundColor Green

# ----------------------------------------------------------
# 4. VALIDAR CSV
# ----------------------------------------------------------

if (-not (Test-Path -LiteralPath $RutaCsv)) {
    throw "No se encuentra el CSV: $RutaCsv"
}

$Usuarios = @(Import-Csv -LiteralPath $RutaCsv -Delimiter ";" -Encoding UTF8)

if ($Usuarios.Count -ne $TotalEmpleados) {
    throw "El CSV debe contener exactamente $TotalEmpleados empleados (tiene $($Usuarios.Count))."
}

$ColumnasObligatorias = @(
    "Nombre","Apellido1","Apellido2","Usuario",
    "Departamento","Puesto","Sede","GruposAdicionales",
    "Perfil","CuotaPersonal"
)

$ColumnasCsv = $Usuarios[0].PSObject.Properties.Name

foreach ($Columna in $ColumnasObligatorias) {
    if ($Columna -notin $ColumnasCsv) {
        throw "Falta la columna CSV: $Columna"
    }
}

if (@($Usuarios.Usuario | Sort-Object -Unique).Count -ne $TotalEmpleados) {
    throw "Hay nombres de usuario duplicados en el CSV."
}

Write-Host "CSV validado: $TotalEmpleados empleados." -ForegroundColor Green

# ----------------------------------------------------------
# 5. FUNCIONES DE APOYO
# ----------------------------------------------------------

function Normalizar-Texto {
    param([string]$Texto)

    if ([string]::IsNullOrWhiteSpace($Texto)) {
        return ""
    }

    $Normalizado = $Texto.Normalize([System.Text.NormalizationForm]::FormD)
    $Normalizado = [regex]::Replace($Normalizado, '\p{Mn}', '')

    return $Normalizado.ToLowerInvariant().Trim()
}

# El fichero es 100% ASCII a proposito (ver bitacora 16/11): las letras con
# tilde se escriben con su codigo para que el script funcione aunque se
# guarde sin BOM o se copie y pegue desde el navegador.
$o_ = [char]0x00F3   # o con tilde
$i_ = [char]0x00ED   # i con tilde

$MapaDepartamentos = @{
    "direccion"                     = @("Direccion","Direcci${o_}n")
    "administracion"                = @("Administracion","Administraci${o_}n y Finanzas")
    "administracion y finanzas"     = @("Administracion","Administraci${o_}n y Finanzas")
    "rrhh"                          = @("RRHH","Recursos Humanos")
    "recursos humanos"              = @("RRHH","Recursos Humanos")
    "comercial"                     = @("Comercial","Comercial y Ventas")
    "comercial y ventas"            = @("Comercial","Comercial y Ventas")
    "marketing"                     = @("Marketing","Marketing")
    "consultoria"                   = @("Consultoria","Consultor${i_}a")
    "desarrollo"                    = @("Desarrollo","Desarrollo")
    "sistemas"                      = @("Sistemas","Sistemas y Ciberseguridad")
    "sistemas y ciberseguridad"     = @("Sistemas","Sistemas y Ciberseguridad")
    "soporte"                       = @("Soporte","Soporte y Atenci${o_}n al Cliente")
    "soporte y atencion al cliente" = @("Soporte","Soporte y Atenci${o_}n al Cliente")
    "legal"                         = @("Legal","Legal y Cumplimiento")
    "legal y cumplimiento"          = @("Legal","Legal y Cumplimiento")
}

# --- Contrasenas ---

$RNG = [System.Security.Cryptography.RandomNumberGenerator]::Create()

function Obtener-IndiceAleatorio {
    param([int]$Maximo)

    $Bytes = New-Object byte[] 4
    $RNG.GetBytes($Bytes)
    $Numero = [BitConverter]::ToUInt32($Bytes, 0)

    return [int]($Numero % [uint32]$Maximo)
}

function Obtener-CaracterAleatorio {
    param([string]$Caracteres)

    return [string]$Caracteres[(Obtener-IndiceAleatorio $Caracteres.Length)]
}

function Generar-Contrasena {
    param(
        [int]$Longitud = 20,
        [string[]]$Prohibidas = @()
    )

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
            $Temporal = $Lista[$i]
            $Lista[$i] = $Lista[$j]
            $Lista[$j] = $Temporal
        }

        $Contrasena = -join $Lista.ToArray()

        # Windows rechaza contrasenas que contienen el usuario o partes
        # del nombre de 3 o mas caracteres. Si pasa, se genera otra.
        $Valida = $true
        foreach ($Palabra in $Prohibidas) {
            if ($Palabra.Length -ge 3 -and
                $Contrasena.ToLowerInvariant().Contains($Palabra.ToLowerInvariant())) {
                $Valida = $false
                break
            }
        }

        if ($Valida) {
            return $Contrasena
        }
    }
}

function Obtener-PalabrasProhibidas {
    param([string]$Sam, [string]$NombreCompleto)

    $Palabras = @($Sam)
    $Palabras += ($NombreCompleto -split '[\s\.,\-_#]+') | Where-Object { $_ -ne "" }
    $Palabras += ($NombreCompleto -split '[\s\.,\-_#]+') | ForEach-Object { Normalizar-Texto $_ } | Where-Object { $_ -ne "" }
    $Palabras += ($Sam -split '\.')

    return @($Palabras | Sort-Object -Unique)
}

# --- Almacen de credenciales (cifrado DPAPI con Export-Clixml) ---

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

# --- Grupos ---

function Agregar-A-Grupo {
    param([string]$Sam, [string]$NombreGrupo)

    $Grupo = Get-ADGroup -Identity $NombreGrupo
    $Usuario = Get-ADUser -Identity $Sam -Properties MemberOf

    if (@($Usuario.MemberOf) -notcontains $Grupo.DistinguishedName) {
        Add-ADGroupMember -Identity $Grupo -Members $Usuario
        Write-Host "  + $NombreGrupo"
    }
}

function Quitar-De-Grupo {
    param([string]$Sam, [string]$NombreGrupo)

    $Grupo = Get-ADGroup -Identity $NombreGrupo
    $Usuario = Get-ADUser -Identity $Sam -Properties MemberOf

    if (@($Usuario.MemberOf) -contains $Grupo.DistinguishedName) {
        Remove-ADGroupMember -Identity $Grupo -Members $Usuario -Confirm:$false
        Write-Host "  - $NombreGrupo (los becarios no reciben el grupo del departamento)" -ForegroundColor Magenta
    }
}

# --- Horario de los becarios ---

function Obtener-HorarioBecario {
    # logonHours: 21 bytes = 168 horas, empezando el domingo a las 00:00 UTC.
    # En cada byte, el bit MENOS significativo es la primera hora del bloque.
    # Se calcula con la zona horaria del servidor (Europe/Madrid). Tras el
    # cambio de horario de verano/invierno hay que volver a ejecutar el script.

    $Zona = [System.TimeZoneInfo]::Local
    $HoyUTC = [DateTime]::SpecifyKind([DateTime]::UtcNow.Date, [DateTimeKind]::Utc)
    $DomingoUTC = $HoyUTC.AddDays(-[int]$HoyUTC.DayOfWeek)

    $BytesHorario = New-Object byte[] 21

    for ($i = 0; $i -lt 168; $i++) {
        $HoraLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($DomingoUTC.AddHours($i), $Zona)

        $DiaLaborable = $HoraLocal.DayOfWeek -notin @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)

        if ($DiaLaborable -and $HoraLocal.Hour -ge 8 -and $HoraLocal.Hour -lt 15) {
            $PosicionByte = [int][math]::Floor($i / 8)
            $PosicionBit = $i % 8
            $BytesHorario[$PosicionByte] = $BytesHorario[$PosicionByte] -bor (1 -shl $PosicionBit)
        }
    }

    return ,$BytesHorario
}

# ----------------------------------------------------------
# 6. POLITICAS DE CONTRASENA
# ----------------------------------------------------------

Write-Host "`n===== POLITICA GENERAL =====" -ForegroundColor Cyan

Set-ADDefaultDomainPasswordPolicy `
    -Identity $DN `
    -MinPasswordLength 12 `
    -ComplexityEnabled $true `
    -PasswordHistoryCount 10 `
    -MaxPasswordAge (New-TimeSpan -Days 90) `
    -LockoutThreshold 5 `
    -LockoutDuration (New-TimeSpan -Minutes 15) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 15)

Write-Host "Politica general aplicada." -ForegroundColor Green

Write-Host "`n===== POLITICA REFORZADA (15 caracteres) =====" -ForegroundColor Cyan

$NombrePSO = "PSO_CiberNova_15"

$ParametrosPSO = @{
    MinPasswordLength        = 15
    ComplexityEnabled        = $true
    PasswordHistoryCount     = 10
    MaxPasswordAge           = (New-TimeSpan -Days 90)
    LockoutThreshold         = 5
    LockoutDuration          = (New-TimeSpan -Minutes 15)
    LockoutObservationWindow = (New-TimeSpan -Minutes 15)
}

$PSO = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$NombrePSO'" -ErrorAction SilentlyContinue

if (-not $PSO) {
    New-ADFineGrainedPasswordPolicy -Name $NombrePSO -Precedence 1 @ParametrosPSO
    Write-Host "PSO creada: $NombrePSO" -ForegroundColor Green
}
else {
    Set-ADFineGrainedPasswordPolicy -Identity $NombrePSO @ParametrosPSO
    Write-Host "PSO actualizada: $NombrePSO" -ForegroundColor Yellow
}

$SujetosPSO = @(Get-ADFineGrainedPasswordPolicySubject -Identity $NombrePSO | ForEach-Object { $_.Name })
if ($SujetosPSO -notcontains "G_Politica_15") {
    Add-ADFineGrainedPasswordPolicySubject -Identity $NombrePSO -Subjects "G_Politica_15"
    Write-Host "PSO aplicada a G_Politica_15" -ForegroundColor Green
}

# ----------------------------------------------------------
# 7. ALTA DE LOS 89 EMPLEADOS
# ----------------------------------------------------------

Write-Host "`n===== ALTA DE EMPLEADOS =====" -ForegroundColor Cyan

$HorarioBecarios = Obtener-HorarioBecario
$ContadorNuevos = 0
$ContadorExistentes = 0

foreach ($Registro in $Usuarios) {

    $Sam = $Registro.Usuario.Trim().ToLowerInvariant()

    $Nombre    = $Registro.Nombre.Trim()
    $Apellido1 = $Registro.Apellido1.Trim()
    $Apellido2 = $Registro.Apellido2.Trim()
    $Apellidos = "$Apellido1 $Apellido2".Trim()
    $NombreCompleto = "$Nombre $Apellidos"

    $DepartamentoNormalizado = Normalizar-Texto $Registro.Departamento
    if (-not $MapaDepartamentos.ContainsKey($DepartamentoNormalizado)) {
        throw "Departamento no reconocido para $Sam : $($Registro.Departamento)"
    }
    $OUDepartamento     = $MapaDepartamentos[$DepartamentoNormalizado][0]
    $NombreDepartamento = $MapaDepartamentos[$DepartamentoNormalizado][1]
    $RutaOU = "OU=$OUDepartamento,$OUUsuarios"

    $Sede = $Registro.Sede.Trim()
    switch (Normalizar-Texto $Sede) {
        "barcelona" { $GrupoSede = "G_Sede_Barcelona" }
        "madrid"    { $GrupoSede = "G_Sede_Madrid" }
        "valencia"  { $GrupoSede = "G_Sede_Valencia" }
        default     { throw "Sede no reconocida para $Sam : $Sede" }
    }

    $UsuarioExistente = Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue

    if (-not $UsuarioExistente) {

        $Contrasena = Generar-Contrasena -Longitud 20 `
            -Prohibidas (Obtener-PalabrasProhibidas -Sam $Sam -NombreCompleto $NombreCompleto)

        New-ADUser `
            -Name $NombreCompleto `
            -GivenName $Nombre `
            -Surname $Apellidos `
            -DisplayName $NombreCompleto `
            -SamAccountName $Sam `
            -UserPrincipalName "$Sam@$($Dominio.DNSRoot)" `
            -Department $NombreDepartamento `
            -Title $Registro.Puesto.Trim() `
            -Office $Sede `
            -Description "Empleado CiberNova" `
            -Path $RutaOU `
            -AccountPassword (ConvertTo-SecureString $Contrasena -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -PasswordNeverExpires $false

        Registrar-Credencial -Usuario $Sam -Contrasena $Contrasena
        $ContadorNuevos++
        Write-Host "Creado: $Sam" -ForegroundColor Green
    }
    else {
        $ContadorExistentes++
        Write-Host "Ya existia: $Sam (no se cambia su contrasena)" -ForegroundColor Yellow
    }

    $PuestoNormalizado = Normalizar-Texto $Registro.Puesto
    $EsBecario = $PuestoNormalizado -like "*becari*"

    # Departamento: los becarios NO lo reciben (Anexo I, apartado 4).
    if ($EsBecario) {
        Quitar-De-Grupo -Sam $Sam -NombreGrupo "G_$OUDepartamento"
    }
    else {
        Agregar-A-Grupo -Sam $Sam -NombreGrupo "G_$OUDepartamento"
    }

    # Sede: todos.
    Agregar-A-Grupo -Sam $Sam -NombreGrupo $GrupoSede

    # Grupos transversales del CSV (sin el prefijo G_ en el CSV).
    $GruposAdicionales = $Registro.GruposAdicionales
    if (-not [string]::IsNullOrWhiteSpace($GruposAdicionales) -and
        $GruposAdicionales.Trim() -notin @("-", [string][char]0x2014)) {   # "-" o guion largo

        foreach ($GrupoTexto in ($GruposAdicionales -split ",")) {
            $GrupoTexto = $GrupoTexto.Trim()
            if ($GrupoTexto -eq "") { continue }

            if ($GrupoTexto.StartsWith("G_")) { $NombreGrupo = $GrupoTexto }
            else { $NombreGrupo = "G_$GrupoTexto" }

            Agregar-A-Grupo -Sam $Sam -NombreGrupo $NombreGrupo
        }
    }

    # Becarios: grupos propios, horario y caducidad.
    if ($EsBecario) {
        Agregar-A-Grupo -Sam $Sam -NombreGrupo "G_Becarios"

        switch ($OUDepartamento) {
            "Desarrollo" { $GrupoBecario = "G_Becarios_Desarrollo" }
            "Marketing"  { $GrupoBecario = "G_Becarios_Marketing" }
            "Soporte"    { $GrupoBecario = "G_Becarios_Soporte" }
            default      { throw "Departamento de becario no previsto: $OUDepartamento ($Sam)" }
        }
        Agregar-A-Grupo -Sam $Sam -NombreGrupo $GrupoBecario

        Set-ADUser -Identity $Sam -Replace @{ logonHours = [byte[]]$HorarioBecarios }
        Set-ADAccountExpiration -Identity $Sam -DateTime $FechaFinBecarios

        Write-Host "  Restricciones de becario aplicadas (L-V 8:00-15:00, caduca 30/06/2027)." -ForegroundColor Cyan
    }

    # Direccion y Sistemas: politica de 15 caracteres.
    if ($OUDepartamento -in @("Direccion","Sistemas")) {
        Agregar-A-Grupo -Sam $Sam -NombreGrupo "G_Politica_15"
    }
}

# ----------------------------------------------------------
# 8. CUENTAS ADMINISTRATIVAS (adm.*)
# ----------------------------------------------------------

Write-Host "`n===== CUENTAS ADMINISTRATIVAS =====" -ForegroundColor Cyan

foreach ($Admin in $Administradores) {

    $Empleado = $Usuarios | Where-Object { $_.Usuario -eq $Admin.Empleado }
    if (-not $Empleado) {
        throw "No se encuentra el empleado asociado a $($Admin.Cuenta)"
    }

    $SamAdmin = $Admin.Cuenta
    $Existe = Get-ADUser -Filter "SamAccountName -eq '$SamAdmin'" -ErrorAction SilentlyContinue

    if (-not $Existe) {
        $NombreAdmin = "ADMIN - $($Empleado.Nombre) $($Empleado.Apellido1) $($Empleado.Apellido2)"

        $ContrasenaAdmin = Generar-Contrasena -Longitud 24 `
            -Prohibidas (Obtener-PalabrasProhibidas -Sam $SamAdmin -NombreCompleto $NombreAdmin)

        New-ADUser `
            -Name $NombreAdmin `
            -GivenName $Empleado.Nombre `
            -Surname "$($Empleado.Apellido1) $($Empleado.Apellido2)" `
            -DisplayName $NombreAdmin `
            -SamAccountName $SamAdmin `
            -UserPrincipalName "$SamAdmin@$($Dominio.DNSRoot)" `
            -Department "Sistemas y Ciberseguridad" `
            -Office "Barcelona" `
            -Description "Cuenta administrativa individual. Uso separado de la cuenta diaria." `
            -Path $OUAdmins `
            -AccountPassword (ConvertTo-SecureString $ContrasenaAdmin -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -PasswordNeverExpires $false

        Registrar-Credencial -Usuario $SamAdmin -Contrasena $ContrasenaAdmin
        Write-Host "Cuenta administrativa creada: $SamAdmin" -ForegroundColor Green
    }
    else {
        Write-Host "Cuenta administrativa existente: $SamAdmin" -ForegroundColor Yellow
    }

    Agregar-A-Grupo -Sam $SamAdmin -NombreGrupo "G_Admin_Sistemas"
    Agregar-A-Grupo -Sam $SamAdmin -NombreGrupo "G_Politica_15"
}

# Solo las cuentas adm. tienen privilegios de administracion (Anexo I, apartado 5).
# "Admins. del dominio" se busca por su SID (<SID del dominio>-512) porque el
# nombre cambia segun el idioma de Windows.
$GrupoAdminsDominio = Get-ADGroup -Identity "$($Dominio.DomainSID.Value)-512"
$GrupoAdminSistemas = Get-ADGroup -Identity "G_Admin_Sistemas" -Properties MemberOf

if (@($GrupoAdminSistemas.MemberOf) -notcontains $GrupoAdminsDominio.DistinguishedName) {
    Add-ADGroupMember -Identity $GrupoAdminsDominio -Members $GrupoAdminSistemas
    Write-Host "G_Admin_Sistemas anadido a $($GrupoAdminsDominio.Name)" -ForegroundColor Green
}

# ----------------------------------------------------------
# 9. RESUMEN
# ----------------------------------------------------------

Write-Host "`n===== RESUMEN FINAL =====" -ForegroundColor Cyan

Write-Host "Empleados en CSV:          $($Usuarios.Count)"
Write-Host "Empleados creados ahora:   $ContadorNuevos"
Write-Host "Empleados que ya existian: $ContadorExistentes"

Write-Host "`nUsuarios por departamento:"
Get-ADUser -Filter * -SearchBase $OUUsuarios -SearchScope Subtree |
    Group-Object { ($_.DistinguishedName -split ',')[1] -replace '^OU=','' } |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host "Cuentas administrativas:"
Get-ADUser -Filter * -SearchBase $OUAdmins |
    Select-Object SamAccountName,Enabled |
    Format-Table -AutoSize

Write-Host "Miembros por grupo:"
Get-ADGroup -Filter * -SearchBase $OUGrupos |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            Grupo    = $_.Name
            Miembros = @(Get-ADGroupMember -Identity $_).Count
        }
    } |
    Format-Table -AutoSize

Write-Host "Archivo cifrado de credenciales: $RutaCredenciales"
Write-Host "Registro de esta ejecucion:      $RutaTranscript"

Write-Host "`nALTA FINALIZADA" -ForegroundColor Green

}
finally {
    if ($RNG) { $RNG.Dispose() }
    Stop-Transcript | Out-Null
}
