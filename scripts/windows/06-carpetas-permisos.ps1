# ==========================================================
# CIBERNOVA - 06. CARPETAS COMPARTIDAS Y PERMISOS NTFS
# Anexo I, apartados 8 y 9 (requisitos P-01 a P-44)
# Dominio: cibernova.local
# Version: 1.3 (26/11/2026)
# Cambios 1.3: CAUSA REAL de los fallos de 1.0-1.2: PowerShell no distingue
#   mayusculas en las variables, y el bucle 'foreach ($r in $Recursos)' del
#   apartado 3 machacaba la variable del tipo FileSystemRights con el texto
#   'Personales'. El tipo pasa a llamarse $FSR y los bucles usan $Rec y $Vieja.
#   (La copia ejecutada en FS01 el 26/11 ya tenia este codigo, aunque su
#   cabecera decia 1.2 por un error al actualizarla.)
# Cambios 1.2: argumentos de tipo enumeracion entre parentesis (no era la causa).
# Cambios 1.1: la funcion Regla usa parametros con tipo y ::new() (en 1.0
#   fallaba en el apartado 4 con "No se encuentra ninguna sobrecarga para
#   FileSystemAccessRule"); los SID se guardan como SecurityIdentifier.
# ----------------------------------------------------------
# Que hace (en este orden):
#   1. Crea el grupo global G_RRHH_Nominas_Consulta (rosa.martinez, P-08):
#      los permisos se dan siempre a grupos, nunca a usuarios.
#   2. Crea los grupos de dominio local DL_<Carpeta>_<Nivel> (modelo AGDLP)
#      en OU=Grupos,OU=CiberNova y mete dentro los grupos globales G_.
#   3. Crea las subcarpetas del Anexo I (apartado 8) dentro de los cuatro
#      recursos compartidos (Departamentos$, Proyectos$, Comun$, Personales$).
#   4. Aplica los permisos NTFS segun la matriz (docs/fase1/08-matriz-permisos.md).
#   5. Activa la auditoria de acceso en Nominas, Expedientes y
#      Proyectos\Sanitario (P-11, P-39).
#
# Idempotente: se puede ejecutar varias veces. Los grupos y carpetas que
# ya existen no se duplican y las ACL se vuelven a dejar exactamente como
# dice el plan (se quitan las reglas explicitas que no esten en el plan).
# Los miembros de mas en un grupo DL_ NO se quitan: solo se avisa.
#
# Donde se ejecuta: en FS01, PowerShell como administrador del dominio.
#   - Las carpetas y ACL se replican solas a FS02 por DFS-R.
#   - Los grupos se crean contra DC01 (-Servidor) y AD los replica a DC02.
#
# Uso:
#   Simulacion (no cambia nada, solo muestra lo que haria):
#     powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1 -Simular
#   Ejecucion real:
#     powershell -ExecutionPolicy Bypass -File .\06-carpetas-permisos.ps1
#   Comprobacion despues: .\96-comprobar-carpetas-permisos.ps1
#
# Niveles (Anexo I, apartado 8, y matriz):
#   CT = control total            M = modificacion        C = consulta
#   L  = listar solo esta carpeta (para poder llegar a una subcarpeta;
#        con ABE el usuario solo ve dentro lo que puede abrir)
#   D  = deposito (deja ficheros, solo ve y gestiona los suyos)
#   I  = intercambio (consulta todo, crea, y solo modifica/borra lo suyo)
#   X  = denegar todo (solo becarios en Proyectos, P-38)
#
# Reglas base en las carpetas con herencia cortada (raices y excepciones):
#   SYSTEM y Administradores: control total (cuentas adm. = administradores
#   del dominio: "control total tecnico", Anexo I apartado 8).
#   DERECHOS DE PROPIETARIO (OWNER RIGHTS): solo leer permisos. Asi el que
#   crea un fichero no puede cambiar sus permisos (nivel M = sin cambiar
#   permisos) ni conserva acceso si cambia de departamento.
#
# svc_backup NO aparece en las ACL: lee toda la estructura con el privilegio
# "Hacer copias de seguridad" (GPO, tarea FS-15).
# Las carpetas personales (Personales\<usuario>) las crea el script de alta
# (02), como exige el Anexo I. Aqui solo se prepara la raiz Personales.
# ==========================================================

param(
    [switch]$Simular,
    [string]$Servidor = "DC01.cibernova.local"
)

$ErrorActionPreference = "Stop"

function Escribir([string]$Tipo, [string]$Texto) {
    $Color = @{ "OK"="Green"; "NUEVO"="Cyan"; "AVISO"="Yellow"; "ERROR"="Red"; "SIM"="Magenta"; "INFO"="Gray" }[$Tipo]
    Write-Host ("[{0}] {1}" -f $Tipo, $Texto) -ForegroundColor $Color
}

# ----------------------------------------------------------
# 0. COMPROBACIONES PREVIAS
# ----------------------------------------------------------
if ($env:COMPUTERNAME -ne "FS01") {
    Escribir "ERROR" "Este script se ejecuta en FS01 (servidor principal de ficheros). Equipo actual: $env:COMPUTERNAME"
    exit 1
}
$Identidad = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Identidad.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Escribir "ERROR" "Abre PowerShell como administrador (con una cuenta de administrador del dominio)."
    exit 1
}
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    if ($Simular) {
        Escribir "ERROR" "Falta el modulo ActiveDirectory. Instalalo con: Install-WindowsFeature RSAT-AD-PowerShell"
        exit 1
    }
    Escribir "INFO" "Instalando el modulo de PowerShell para Active Directory (RSAT-AD-PowerShell)..."
    Install-WindowsFeature RSAT-AD-PowerShell | Out-Null
}
Import-Module ActiveDirectory
if ($Simular) { Escribir "SIM" "MODO SIMULACION: no se cambia nada en AD ni en las carpetas." }

$OUGrupos = (Get-ADOrganizationalUnit -Server $Servidor -Filter 'Name -eq "Grupos"' |
    Where-Object { $_.DistinguishedName -like "*OU=CiberNova,*" } | Select-Object -First 1).DistinguishedName
if (-not $OUGrupos) { Escribir "ERROR" "No se encuentra OU=Grupos,OU=CiberNova (script 01)."; exit 1 }

# ----------------------------------------------------------
# PLAN (generado desde la matriz; no editar a mano sin cambiar la matriz)
# ----------------------------------------------------------
$GruposGlobalesNuevos = @(
    @{Nombre='G_RRHH_Nominas_Consulta'; Miembros=@('rosa.martinez'); Descripcion='Consulta de RRHH\Nominas (responsable de Administracion, P-08)'}
)

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

$Recursos = @('Departamentos', 'Proyectos', 'Comun', 'Personales')

# ----------------------------------------------------------
# FUNCIONES DE GRUPOS
# ----------------------------------------------------------
function Asegurar-Grupo([string]$Nombre, [string]$Ambito, [string]$Descripcion) {
    $g = Get-ADGroup -Server $Servidor -Filter "SamAccountName -eq '$Nombre'" -ErrorAction SilentlyContinue
    if ($g) {
        if ($g.GroupScope -ne $Ambito) { Escribir "AVISO" "$Nombre existe con ambito $($g.GroupScope) (se esperaba $Ambito)" }
        return $g
    }
    if ($Simular) { Escribir "SIM" "Crearia el grupo $Ambito $Nombre"; return $null }
    New-ADGroup -Server $Servidor -Name $Nombre -SamAccountName $Nombre -GroupCategory Security `
        -GroupScope $Ambito -Path $OUGrupos -Description $Descripcion
    Escribir "NUEVO" "Grupo $Ambito creado: $Nombre"
    return (Get-ADGroup -Server $Servidor -Identity $Nombre)
}

function Asegurar-Miembros([string]$Grupo, [string[]]$Miembros) {
    $g = Get-ADGroup -Server $Servidor -Filter "SamAccountName -eq '$Grupo'" -ErrorAction SilentlyContinue
    if (-not $g) { if ($Simular) { Escribir "SIM" "  $Grupo <- $($Miembros -join ', ')" }; return }
    $Actuales = @(Get-ADGroupMember -Server $Servidor -Identity $g | ForEach-Object { $_.SamAccountName })
    foreach ($m in $Miembros) {
        if ($Actuales -contains $m) { continue }
        if ($Simular) { Escribir "SIM" "  Anadiria $m a $Grupo"; continue }
        Add-ADGroupMember -Server $Servidor -Identity $g -Members $m
        Escribir "NUEVO" "  $m -> $Grupo"
    }
    foreach ($a in $Actuales) {
        if ($Miembros -notcontains $a) { Escribir "AVISO" "  $Grupo tiene un miembro no previsto en la matriz: $a (no se quita)" }
    }
}

# ----------------------------------------------------------
# 1. GRUPOS GLOBALES NUEVOS
# ----------------------------------------------------------
Write-Host "`n===== 1. GRUPOS GLOBALES NUEVOS =====" -ForegroundColor Cyan
foreach ($gg in $GruposGlobalesNuevos) {
    Asegurar-Grupo -Nombre $gg.Nombre -Ambito Global -Descripcion $gg.Descripcion | Out-Null
    Asegurar-Miembros -Grupo $gg.Nombre -Miembros $gg.Miembros
}

# ----------------------------------------------------------
# 2. GRUPOS DE DOMINIO LOCAL (DL_) Y ANIDAMIENTO G_ -> DL_
# ----------------------------------------------------------
Write-Host "`n===== 2. GRUPOS DL_ (AGDLP) =====" -ForegroundColor Cyan
$DLs = [ordered]@{}
foreach ($c in $Plan) {
    $Ruta = if ($c.Sub) { "$($c.Recurso)\$($c.Sub)" } else { $c.Recurso }
    foreach ($p in $c.Permisos) {
        if (-not $DLs.Contains($p.DL)) { $DLs[$p.DL] = @{ Miembros = $p.Miembros; Desc = "Nivel $($p.Nivel) en $Ruta" } }
    }
}
$SIDs = @{}
foreach ($dl in $DLs.Keys) {
    $g = Asegurar-Grupo -Nombre $dl -Ambito DomainLocal -Descripcion $DLs[$dl].Desc
    if ($g) { $SIDs[$dl] = New-Object System.Security.Principal.SecurityIdentifier ([string]$g.SID.Value) } else { Escribir "SIM" "  ($dl no existe todavia: en la ejecucion real se crea)" }
    Asegurar-Miembros -Grupo $dl -Miembros $DLs[$dl].Miembros
}
Escribir "OK" "$($DLs.Count) grupos DL_ revisados."

# ----------------------------------------------------------
# 3. CARPETAS
# ----------------------------------------------------------
Write-Host "`n===== 3. CARPETAS (Anexo I, apartado 8) =====" -ForegroundColor Cyan
$Base = @{}
foreach ($Rec in $Recursos) {
    $s = Get-SmbShare -Name "$Rec`$" -ErrorAction SilentlyContinue
    if (-not $s) { Escribir "ERROR" "No existe el recurso compartido $Rec`$ en FS01."; exit 1 }
    $Base[$Rec] = $s.Path
    Escribir "INFO" "$Rec`$ -> $($s.Path)"
}
foreach ($c in $Plan) {
    $c.Ruta = if ($c.Sub) { Join-Path $Base[$c.Recurso] $c.Sub } else { $Base[$c.Recurso] }
    if (Test-Path -LiteralPath $c.Ruta) { continue }
    if ($Simular) { Escribir "SIM" "Crearia la carpeta $($c.Ruta)"; continue }
    New-Item -ItemType Directory -Path $c.Ruta | Out-Null
    Escribir "NUEVO" "Carpeta creada: $($c.Ruta)"
}

# ----------------------------------------------------------
# 4. PERMISOS NTFS
# ----------------------------------------------------------
Write-Host "`n===== 4. PERMISOS NTFS =====" -ForegroundColor Cyan
$FSR  = [System.Security.AccessControl.FileSystemRights]
$IF = [System.Security.AccessControl.InheritanceFlags]
$PF = [System.Security.AccessControl.PropagationFlags]
$AT = [System.Security.AccessControl.AccessControlType]
$Todo     = $IF::ContainerInherit -bor $IF::ObjectInherit
$Ninguna  = $IF::None
$SidSystem      = New-Object Security.Principal.SecurityIdentifier "S-1-5-18"
$SidAdmins      = New-Object Security.Principal.SecurityIdentifier "S-1-5-32-544"
$SidOwnerRights = New-Object Security.Principal.SecurityIdentifier "S-1-3-4"
$SidCreator     = New-Object Security.Principal.SecurityIdentifier "S-1-3-0"
$SidTodos       = New-Object Security.Principal.SecurityIdentifier "S-1-1-0"

$Listar = $FSR::ListDirectory -bor $FSR::ReadAttributes -bor $FSR::ReadExtendedAttributes -bor $FSR::ReadPermissions -bor $FSR::Traverse -bor $FSR::Synchronize
$Crear  = $FSR::CreateFiles -bor $FSR::CreateDirectories

# Parametros con tipo: PowerShell convierte (y desenvuelve) cada valor antes de
# llamar al constructor. Sin tipos, New-Object no encontraba el constructor
# ("No se encuentra ninguna sobrecarga ... 5") en Windows PowerShell 5.1 (v1.0).
function Regla(
    [System.Security.Principal.SecurityIdentifier]$Sid,
    [System.Security.AccessControl.FileSystemRights]$Derechos,
    [System.Security.AccessControl.InheritanceFlags]$Herencia,
    [System.Security.AccessControl.PropagationFlags]$Propagacion = [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]$Tipo = [System.Security.AccessControl.AccessControlType]::Allow
) {
    if (-not $Sid) { throw "Regla sin SID (grupo no encontrado)" }
    return [System.Security.AccessControl.FileSystemAccessRule]::new($Sid, $Derechos, $Herencia, $Propagacion, $Tipo)
}

function Reglas-De-Nivel([string]$Nivel, $Sid) {
    switch ($Nivel) {
        "CT" { @(Regla $Sid ($FSR::FullControl) $Todo) }
        "M"  { @(Regla $Sid ($FSR::Modify -bor ($FSR::Synchronize)) $Todo) }
        "C"  { @(Regla $Sid ($FSR::ReadAndExecute -bor ($FSR::Synchronize)) $Todo) }
        "L"  { @(Regla $Sid $Listar $Ninguna) }
        "D"  { @( (Regla $Sid ($Listar -bor $Crear) $Ninguna),
                  (Regla $SidCreator ($FSR::Modify -bor ($FSR::Synchronize)) $Todo ($PF::InheritOnly)) ) }
        "I"  { @( (Regla $Sid ($FSR::ReadAndExecute -bor ($FSR::Synchronize)) $Todo),
                  (Regla $Sid $Crear $Ninguna),
                  (Regla $SidCreator ($FSR::Modify -bor ($FSR::Synchronize)) $Todo ($PF::InheritOnly)) ) }
        "X"  { @(Regla $Sid ($FSR::FullControl) $Todo ($PF::None) ($AT::Deny)) }
        default { throw "Nivel desconocido: $Nivel" }
    }
}

$Cambios = 0
foreach ($c in $Plan) {
    $Texto = ($c.Permisos | ForEach-Object { "$($_.Nivel):$($_.DL)" }) -join ", "
    if ($Simular) {
        Escribir "SIM" ("{0}  [herencia {1}]  {2}" -f $c.Ruta, $(if ($c.Proteger) { "CORTADA" } else { "heredada" }), $Texto)
        continue
    }
    # GetAccessControl('Access') solo lee y escribe la DACL: evita el error
    # de Set-Acl al intentar reescribir el propietario.
    $dir = Get-Item -LiteralPath $c.Ruta
    $acl = $dir.GetAccessControl('Access')
    foreach ($Vieja in @($acl.Access | Where-Object { -not $_.IsInherited })) { [void]$acl.RemoveAccessRuleSpecific($Vieja) }
    $acl.SetAccessRuleProtection([bool]$c.Proteger, $false)
    if ($c.Proteger) {
        $acl.AddAccessRule((Regla $SidSystem ($FSR::FullControl) $Todo))
        $acl.AddAccessRule((Regla $SidAdmins ($FSR::FullControl) $Todo))
        $acl.AddAccessRule((Regla $SidOwnerRights ($FSR::ReadPermissions) $Todo))
    }
    foreach ($p in $c.Permisos) {
        foreach ($regla in (Reglas-De-Nivel $p.Nivel $SIDs[$p.DL])) { $acl.AddAccessRule($regla) }
    }
    $dir.SetAccessControl($acl)
    $Cambios++
    Escribir "OK" ("{0}  [herencia {1}]  {2}" -f $c.Ruta, $(if ($c.Proteger) { "cortada" } else { "heredada" }), $Texto)
}

# ----------------------------------------------------------
# 5. AUDITORIA DE ACCESO (P-11, P-39)
# ----------------------------------------------------------
Write-Host "`n===== 5. AUDITORIA (SACL) =====" -ForegroundColor Cyan
# Se registran los accesos de TODOS (tambien Sistemas): lectura, escritura,
# borrado y cambios de permisos, con exito y con error. La GPO
# GPO_Servidores_Auditoria activa la categoria "Sistema de archivos";
# los eventos (4663) salen en el visor de eventos de FS01/FS02, registro Seguridad.
$DerechosAuditados = $FSR::ReadData -bor $FSR::WriteData -bor $FSR::AppendData -bor $FSR::Delete -bor `
                     $FSR::DeleteSubdirectoriesAndFiles -bor $FSR::ChangePermissions -bor $FSR::TakeOwnership
$Banderas = [System.Security.AccessControl.AuditFlags]::Success -bor [System.Security.AccessControl.AuditFlags]::Failure
foreach ($c in ($Plan | Where-Object { $_.Auditar })) {
    if ($Simular) { Escribir "SIM" "Auditaria (exito y error, Todos): $($c.Ruta)"; continue }
    $dir = Get-Item -LiteralPath $c.Ruta
    $acl = $dir.GetAccessControl('Audit')
    foreach ($a in @($acl.GetAuditRules($true, $false, [Security.Principal.SecurityIdentifier]))) { [void]$acl.RemoveAuditRuleSpecific($a) }
    $acl.AddAuditRule([System.Security.AccessControl.FileSystemAuditRule]::new($SidTodos, [System.Security.AccessControl.FileSystemRights]$DerechosAuditados, [System.Security.AccessControl.InheritanceFlags]$Todo, [System.Security.AccessControl.PropagationFlags]::None, [System.Security.AccessControl.AuditFlags]$Banderas))
    $dir.SetAccessControl($acl)
    Escribir "OK" "Auditoria activada: $($c.Ruta)"
}

# ----------------------------------------------------------
# RESUMEN
# ----------------------------------------------------------
Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
if ($Simular) {
    Escribir "SIM" "Simulacion terminada. Para aplicar, vuelve a ejecutar sin -Simular."
} else {
    Escribir "OK" "$($DLs.Count) grupos DL_, $($Plan.Count) carpetas, $Cambios ACL aplicadas."
    Escribir "INFO" "Los usuarios reciben los grupos nuevos al volver a iniciar sesion."
    Escribir "INFO" "Siguiente: .\96-comprobar-carpetas-permisos.ps1 y, en FS02, comprobar que han llegado las carpetas (DFS-R)."
}
