# ==========================================================
# CIBERNOVA - 96. COMPROBAR CARPETAS Y PERMISOS (script 06)
# Version: 1.2 (26/11/2026)
# Cambios 1.2: compara la suma de derechos por grupo (carpeta y heredado) y no
#   regla a regla: Windows fusiona las dos reglas del nivel I (Intercambio) y la
#   v1.1 daba un falso ERROR en Comun\Intercambio.
# Cambios 1.1: variable de tipo $R renombrada a $FSR y bucle $r a $Rec
#   (PowerShell no distingue mayusculas: el mismo fallo que el script 06 v1.2).
# ----------------------------------------------------------
# Solo lee: no cambia nada. Compara lo que hay en AD y en las carpetas
# con el plan del script 06 (mismo bloque $Plan) y saca un resumen
# OK/ERROR por carpeta. Sirve como evidencia (captura de la salida).
#
# Uso (en FS01 o FS02, PowerShell como administrador):
#   powershell -ExecutionPolicy Bypass -File .\96-comprobar-carpetas-permisos.ps1
#   En FS02 comprueba ademas que DFS-R ha replicado carpetas y ACL.
# ==========================================================

param([string]$Servidor = "DC01.cibernova.local")

Import-Module ActiveDirectory
$Errores = 0
function Ok([string]$t)    { Write-Host "[OK]    $t" -ForegroundColor Green }
function Mal([string]$t)   { Write-Host "[ERROR] $t" -ForegroundColor Red; $script:Errores++ }
function Aviso([string]$t) { Write-Host "[AVISO] $t" -ForegroundColor Yellow }

$Plan = @(
    @{Recurso='Departamentos'; Sub=''; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='L'; DL='DL_Departamentos_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia','G_Auditor_Externo')}
    )},
    @{Recurso='Departamentos'; Sub='Direccion'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Direccion_M'; Miembros=@('G_Direccion')},
        @{Nivel='L'; DL='DL_Direccion_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='Direccion\Actas'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Direccion\Estrategia'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Direccion_Estrategia_C'; Miembros=@('G_Responsables')}
    )},
    @{Recurso='Departamentos'; Sub='Direccion\Comunicados'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Direccion_Comunicados_C'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='Administracion'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Administracion_M'; Miembros=@('G_Administracion')},
        @{Nivel='C'; DL='DL_Administracion_C'; Miembros=@('G_Direccion')},
        @{Nivel='L'; DL='DL_Administracion_L'; Miembros=@('G_Comercial','G_Legal')}
    )},
    @{Recurso='Departamentos'; Sub='Administracion\Contabilidad'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Administracion\Facturacion'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Administracion_Facturacion_C'; Miembros=@('G_Legal')}
    )},
    @{Recurso='Departamentos'; Sub='Administracion\Presupuestos'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Administracion_Presupuestos_M'; Miembros=@('G_Comercial')}
    )},
    @{Recurso='Departamentos'; Sub='RRHH'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_RRHH_M'; Miembros=@('G_RRHH')},
        @{Nivel='L'; DL='DL_RRHH_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='RRHH\Expedientes'; Proteger=$false; Auditar=$true; Permisos=@(
        @{Nivel='C'; DL='DL_RRHH_Expedientes_C'; Miembros=@('G_Direccion')}
    )},
    @{Recurso='Departamentos'; Sub='RRHH\Nominas'; Proteger=$true; Auditar=$true; Permisos=@(
        @{Nivel='M'; DL='DL_RRHH_Nominas_M'; Miembros=@('G_RRHH_Nominas')},
        @{Nivel='C'; DL='DL_RRHH_Nominas_C'; Miembros=@('G_RRHH_Nominas_Consulta')}
    )},
    @{Recurso='Departamentos'; Sub='RRHH\Seleccion'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_RRHH_Seleccion_C'; Miembros=@('G_Direccion')}
    )},
    @{Recurso='Departamentos'; Sub='RRHH\Buzon_Documentacion'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='D'; DL='DL_RRHH_Buzon_D'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='Comercial'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comercial_M'; Miembros=@('G_Comercial')},
        @{Nivel='C'; DL='DL_Comercial_C'; Miembros=@('G_Direccion','G_Marketing')},
        @{Nivel='L'; DL='DL_Comercial_L'; Miembros=@('G_Consultoria')}
    )},
    @{Recurso='Departamentos'; Sub='Comercial\Clientes'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Comercial\Ofertas'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Comercial_Ofertas_C'; Miembros=@('G_Consultoria')}
    )},
    @{Recurso='Departamentos'; Sub='Marketing'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Marketing_M'; Miembros=@('G_Marketing')},
        @{Nivel='C'; DL='DL_Marketing_C'; Miembros=@('G_Direccion','G_Becarios_Marketing')},
        @{Nivel='L'; DL='DL_Marketing_L'; Miembros=@('G_Comercial')}
    )},
    @{Recurso='Departamentos'; Sub='Marketing\Campanas'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Marketing_Campanas_M'; Miembros=@('G_Comercial','G_Becarios_Marketing')}
    )},
    @{Recurso='Departamentos'; Sub='Marketing\Diseno'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Consultoria'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Consultoria_M'; Miembros=@('G_Consultoria','G_Desarrollo')},
        @{Nivel='C'; DL='DL_Consultoria_C'; Miembros=@('G_Soporte','G_Direccion')}
    )},
    @{Recurso='Departamentos'; Sub='Consultoria\Metodologia'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Consultoria\Informes'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Desarrollo'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Desarrollo_M'; Miembros=@('G_Desarrollo')},
        @{Nivel='L'; DL='DL_Desarrollo_L'; Miembros=@('G_Becarios_Desarrollo','G_Sistemas','G_Soporte','G_Consultoria')}
    )},
    @{Recurso='Departamentos'; Sub='Desarrollo\Codigo'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Desarrollo_Codigo_C'; Miembros=@('G_Becarios_Desarrollo','G_Consultoria')}
    )},
    @{Recurso='Departamentos'; Sub='Desarrollo\Releases'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Desarrollo_Releases_C'; Miembros=@('G_Becarios_Desarrollo','G_Sistemas','G_Soporte')}
    )},
    @{Recurso='Departamentos'; Sub='Desarrollo\Becarios'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Desarrollo_Becarios_M'; Miembros=@('G_Becarios_Desarrollo')}
    )},
    @{Recurso='Departamentos'; Sub='Sistemas'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='CT'; DL='DL_Sistemas_CT'; Miembros=@('G_Sistemas')},
        @{Nivel='L'; DL='DL_Sistemas_L'; Miembros=@('G_Soporte','G_Auditor_Externo')}
    )},
    @{Recurso='Departamentos'; Sub='Sistemas\Documentacion'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Sistemas_Documentacion_C'; Miembros=@('G_Soporte','G_Auditor_Externo')}
    )},
    @{Recurso='Departamentos'; Sub='Sistemas\Software'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Sistemas_Software_C'; Miembros=@('G_Soporte')}
    )},
    @{Recurso='Departamentos'; Sub='Sistemas\Privado'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Departamentos'; Sub='Soporte'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Soporte_M'; Miembros=@('G_Soporte','G_Sistemas')},
        @{Nivel='C'; DL='DL_Soporte_C'; Miembros=@('G_Becarios_Soporte')},
        @{Nivel='L'; DL='DL_Soporte_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='Soporte\Incidencias'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Soporte_Incidencias_C'; Miembros=@('G_Consultoria','G_Desarrollo')},
        @{Nivel='M'; DL='DL_Soporte_Incidencias_M'; Miembros=@('G_Becarios_Soporte')}
    )},
    @{Recurso='Departamentos'; Sub='Soporte\Base_Conocimiento'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Soporte_BaseConocimiento_C'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Departamentos'; Sub='Legal'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Legal_M'; Miembros=@('G_Legal')},
        @{Nivel='L'; DL='DL_Legal_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia','G_Auditor_Externo')}
    )},
    @{Recurso='Departamentos'; Sub='Legal\Contratos'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Legal_Contratos_C'; Miembros=@('G_Direccion','G_Administracion','G_Comercial')}
    )},
    @{Recurso='Departamentos'; Sub='Legal\Politicas'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Legal_Politicas_C'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')},
        @{Nivel='M'; DL='DL_Legal_Politicas_M'; Miembros=@('G_Sistemas')}
    )},
    @{Recurso='Departamentos'; Sub='Legal\Comite_Seguridad'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Legal_ComiteSeguridad_M'; Miembros=@('G_Comite_Seguridad')},
        @{Nivel='C'; DL='DL_Legal_ComiteSeguridad_C'; Miembros=@('G_Auditor_Externo')}
    )},
    @{Recurso='Proyectos'; Sub=''; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='X'; DL='DL_Proyectos_Denegar'; Miembros=@('G_Becarios')},
        @{Nivel='L'; DL='DL_Proyectos_L'; Miembros=@('G_Proyecto_Sanitario','G_Proyecto_Financiero','G_Legal','G_Direccion')}
    )},
    @{Recurso='Proyectos'; Sub='Sanitario'; Proteger=$false; Auditar=$true; Permisos=@(
        @{Nivel='X'; DL='DL_Proyectos_Denegar'; Miembros=@('G_Becarios')},
        @{Nivel='M'; DL='DL_Proyectos_Sanitario_M'; Miembros=@('G_Proyecto_Sanitario')},
        @{Nivel='C'; DL='DL_Proyectos_Sanitario_C'; Miembros=@('G_Legal','G_Direccion')}
    )},
    @{Recurso='Proyectos'; Sub='Financiero'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='X'; DL='DL_Proyectos_Denegar'; Miembros=@('G_Becarios')},
        @{Nivel='M'; DL='DL_Proyectos_Financiero_M'; Miembros=@('G_Proyecto_Financiero')},
        @{Nivel='C'; DL='DL_Proyectos_Financiero_C'; Miembros=@('G_Legal','G_Direccion')}
    )},
    @{Recurso='Comun'; Sub=''; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='C'; DL='DL_Comun_C'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia','G_Recepcion')}
    )},
    @{Recurso='Comun'; Sub='Plantillas'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comun_Plantillas_M'; Miembros=@('G_Marketing')}
    )},
    @{Recurso='Comun'; Sub='Intercambio'; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='I'; DL='DL_Comun_Intercambio_I'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )},
    @{Recurso='Comun'; Sub='Formacion'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comun_Formacion_M'; Miembros=@('G_RRHH')}
    )},
    @{Recurso='Comun'; Sub='Sedes'; Proteger=$false; Auditar=$false; Permisos=@(
    )},
    @{Recurso='Comun'; Sub='Sedes\Barcelona'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comun_Sedes_Barcelona_M'; Miembros=@('G_Sede_Barcelona')}
    )},
    @{Recurso='Comun'; Sub='Sedes\Madrid'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comun_Sedes_Madrid_M'; Miembros=@('G_Sede_Madrid')}
    )},
    @{Recurso='Comun'; Sub='Sedes\Valencia'; Proteger=$false; Auditar=$false; Permisos=@(
        @{Nivel='M'; DL='DL_Comun_Sedes_Valencia_M'; Miembros=@('G_Sede_Valencia')}
    )},
    @{Recurso='Personales'; Sub=''; Proteger=$true; Auditar=$false; Permisos=@(
        @{Nivel='L'; DL='DL_Personales_L'; Miembros=@('G_Sede_Barcelona','G_Sede_Madrid','G_Sede_Valencia')}
    )}
)

$GruposGlobalesNuevos = @{ 'G_RRHH_Nominas_Consulta' = @('rosa.martinez') }

# Derechos esperados por nivel (los mismos que pone el script 06)
$FSR = [System.Security.AccessControl.FileSystemRights]
$Listar = $FSR::ListDirectory -bor $FSR::ReadAttributes -bor $FSR::ReadExtendedAttributes -bor $FSR::ReadPermissions -bor $FSR::Traverse -bor $FSR::Synchronize
$Crear  = $FSR::CreateFiles -bor $FSR::CreateDirectories
# Para cada nivel: derechos sobre la propia carpeta y derechos que heredan
# subcarpetas y archivos. Windows puede fusionar dos reglas del mismo grupo en
# una sola entrada (pasa en Intercambio), por eso se comparan las sumas y no
# las reglas una a una (cambio de la v1.2).
$Sync = [int]$FSR::Synchronize
$Esperado = @{
    'CT' = @([int]$FSR::FullControl, [int]$FSR::FullControl)
    'M'  = @([int]($FSR::Modify -bor $FSR::Synchronize), [int]($FSR::Modify -bor $FSR::Synchronize))
    'C'  = @([int]($FSR::ReadAndExecute -bor $FSR::Synchronize), [int]($FSR::ReadAndExecute -bor $FSR::Synchronize))
    'L'  = @([int]$Listar, 0)
    'D'  = @([int]($Listar -bor $Crear), 0)
    'I'  = @([int]($FSR::ReadAndExecute -bor $FSR::Synchronize -bor $Crear), [int]($FSR::ReadAndExecute -bor $FSR::Synchronize))
    'X'  = @([int]$FSR::FullControl, [int]$FSR::FullControl)
}
$IO   = [System.Security.AccessControl.PropagationFlags]::InheritOnly
$Hijo = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

# ----- 1. Grupos -----
Write-Host "`n===== 1. GRUPOS =====" -ForegroundColor Cyan
foreach ($n in $GruposGlobalesNuevos.Keys) {
    $g = Get-ADGroup -Server $Servidor -Filter "SamAccountName -eq '$n'" -ErrorAction SilentlyContinue
    if (-not $g) { Mal "Falta el grupo $n"; continue }
    $m = @(Get-ADGroupMember -Server $Servidor -Identity $g | ForEach-Object SamAccountName)
    foreach ($x in $GruposGlobalesNuevos[$n]) { if ($m -notcontains $x) { Mal "$n no contiene $x" } }
    Ok "$n ($($g.GroupScope)): $($m -join ', ')"
}
$SIDs = @{}; $Vistos = @{}
foreach ($c in $Plan) { foreach ($p in $c.Permisos) {
    if ($Vistos.ContainsKey($p.DL)) { continue }; $Vistos[$p.DL] = $true
    $g = Get-ADGroup -Server $Servidor -Filter "SamAccountName -eq '$($p.DL)'" -ErrorAction SilentlyContinue
    if (-not $g) { Mal "Falta el grupo $($p.DL)"; continue }
    $SIDs[$p.DL] = $g.SID.Value
    if ($g.GroupScope -ne 'DomainLocal') { Mal "$($p.DL) es $($g.GroupScope), deberia ser DomainLocal" }
    $m = @(Get-ADGroupMember -Server $Servidor -Identity $g | ForEach-Object SamAccountName)
    $faltan = @($p.Miembros | Where-Object { $m -notcontains $_ })
    $sobran = @($m | Where-Object { $p.Miembros -notcontains $_ })
    if ($faltan) { Mal "$($p.DL): faltan $($faltan -join ', ')" }
    if ($sobran) { Aviso "$($p.DL): miembros no previstos $($sobran -join ', ')" }
}}
Ok "$($SIDs.Count) grupos DL_ encontrados"

# ----- 2. Carpetas y ACL -----
Write-Host "`n===== 2. CARPETAS Y ACL =====" -ForegroundColor Cyan
$Base = @{}
foreach ($Rec in 'Departamentos','Proyectos','Comun','Personales') {
    $s = Get-SmbShare -Name "$Rec`$" -ErrorAction SilentlyContinue
    if ($s) { $Base[$Rec] = $s.Path } else { Mal "No existe el recurso $Rec`$" }
}
$SidsBase = @('S-1-5-18', 'S-1-5-32-544', 'S-1-3-4', 'S-1-3-0')
foreach ($c in $Plan) {
    if (-not $Base[$c.Recurso]) { continue }
    $Ruta = if ($c.Sub) { Join-Path $Base[$c.Recurso] $c.Sub } else { $Base[$c.Recurso] }
    if (-not (Test-Path -LiteralPath $Ruta)) { Mal "No existe $Ruta"; continue }
    $acl = (Get-Item -LiteralPath $Ruta).GetAccessControl('Access')
    $fallos = @()
    if ($acl.AreAccessRulesProtected -ne [bool]$c.Proteger) { $fallos += "herencia (protegida=$($acl.AreAccessRulesProtected))" }
    $expl = @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
    foreach ($p in $c.Permisos) {
        $sid = $SIDs[$p.DL]; if (-not $sid) { $fallos += "$($p.DL) sin SID"; continue }
        $tipo = if ($p.Nivel -eq 'X') { 'Deny' } else { 'Allow' }
        $mias = @($expl | Where-Object { $_.IdentityReference.Value -eq $sid -and "$($_.AccessControlType)" -eq $tipo })
        $enCarpeta = 0; $heredado = 0
        foreach ($m in $mias) {
            if (($m.PropagationFlags -band $IO) -ne $IO) { $enCarpeta = $enCarpeta -bor [int]$m.FileSystemRights }
            if (($m.InheritanceFlags -band $Hijo) -eq $Hijo) { $heredado = $heredado -bor [int]$m.FileSystemRights }
        }
        $esp = $Esperado[$p.Nivel]
        if ((($enCarpeta -bor $Sync) -ne ($esp[0] -bor $Sync)) -or (($heredado -bor $Sync) -ne ($esp[1] -bor $Sync) -and -not ($heredado -eq 0 -and $esp[1] -eq 0))) {
            $fallos += "$($p.Nivel):$($p.DL) (carpeta=$enCarpeta heredado=$heredado)"
        }
    }
    $previstos = @($c.Permisos | ForEach-Object { $SIDs[$_.DL] }) + $SidsBase
    foreach ($e in $expl) {
        if ($previstos -notcontains $e.IdentityReference.Value) {
            $nombre = try { $e.IdentityReference.Translate([Security.Principal.NTAccount]).Value } catch { $e.IdentityReference.Value }
            $fallos += "regla no prevista: $nombre"
        }
    }
    if ($c.Auditar) {
        $sacl = (Get-Item -LiteralPath $Ruta).GetAccessControl('Audit')
        if (@($sacl.GetAuditRules($true, $false, [Security.Principal.SecurityIdentifier])).Count -eq 0) { $fallos += "sin auditoria" }
    }
    $etq = $(if ($c.Proteger) { ' [herencia cortada]' } else { '' }) + $(if ($c.Auditar) { ' [auditada]' } else { '' })
    if ($fallos) { Mal "$Ruta -> $($fallos -join '; ')" } else { Ok "$Ruta$etq" }
}

Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
if ($Errores -eq 0) { Ok "$($Plan.Count) carpetas y $($SIDs.Count) grupos DL_ segun la matriz. 0 errores." }
else { Mal "$Errores errores. Revisa las lineas [ERROR]." }
