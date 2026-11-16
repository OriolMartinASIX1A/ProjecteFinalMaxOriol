# ==========================================================
# CIBERNOVA - 01. CREACION DE OU Y GRUPOS GLOBALES
# Dominio: cibernova.local
# Version: 2.1 (16/11/2026)
# ----------------------------------------------------------
# Idempotente: se puede ejecutar varias veces. Si una OU o un
# grupo ya existen, no los duplica.
# Ejecutar en DC01 con una cuenta de administrador del dominio:
#   powershell -ExecutionPolicy Bypass -File .\01-crear-ou-grupos.ps1
# ----------------------------------------------------------
# Cambios respecto a la version 1 (ver docs/fase1/03-memoria-tecnica.md):
#  - El nombre de la OU "Cuentas especiales" se define una sola vez
#    (antes se creaba con espacio y se buscaba sin espacio).
#  - Los grupos se buscan en todo el dominio (no solo en OU=Grupos)
#    para no fallar si ya existen en otra ubicacion.
#  - El resumen final usa -Filter * (antes pedia el filtro por pantalla).
# Cambios de la version 2.1:
#  - Nuevas OU "Equipos" (Barcelona, Madrid, Valencia, Recepcion) y
#    "Servidores", para poder vincular GPO a equipos (el contenedor por
#    defecto "Computers" no admite GPO). Los controladores de dominio se
#    quedan en su OU "Domain Controllers" y no se mueven.
# ==========================================================

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

# ----------------------------------------------------------
# CONFIGURACION
# ----------------------------------------------------------

$NombreOUEspeciales = "Cuentas especiales"

$Departamentos = @(
    "Direccion",
    "Administracion",
    "RRHH",
    "Comercial",
    "Marketing",
    "Consultoria",
    "Desarrollo",
    "Sistemas",
    "Soporte",
    "Legal"
)

$Grupos = @(
    @{Nombre="G_Direccion";Descripcion="Usuarios del departamento de Direccion"},
    @{Nombre="G_Administracion";Descripcion="Usuarios del departamento de Administracion"},
    @{Nombre="G_RRHH";Descripcion="Usuarios del departamento de RRHH"},
    @{Nombre="G_Comercial";Descripcion="Usuarios del departamento Comercial"},
    @{Nombre="G_Marketing";Descripcion="Usuarios del departamento Marketing"},
    @{Nombre="G_Consultoria";Descripcion="Usuarios del departamento Consultoria"},
    @{Nombre="G_Desarrollo";Descripcion="Usuarios del departamento Desarrollo"},
    @{Nombre="G_Sistemas";Descripcion="Usuarios del departamento Sistemas"},
    @{Nombre="G_Soporte";Descripcion="Usuarios del departamento Soporte"},
    @{Nombre="G_Legal";Descripcion="Usuarios del departamento Legal"},

    @{Nombre="G_Sede_Barcelona";Descripcion="Usuarios de la sede Barcelona"},
    @{Nombre="G_Sede_Madrid";Descripcion="Usuarios de la sede Madrid"},
    @{Nombre="G_Sede_Valencia";Descripcion="Usuarios de la sede Valencia"},

    @{Nombre="G_Responsables";Descripcion="Responsables de departamento"},
    @{Nombre="G_Comite_Seguridad";Descripcion="Comite de seguridad"},
    @{Nombre="G_RRHH_Nominas";Descripcion="Personal autorizado para gestionar nominas"},
    @{Nombre="G_Proyecto_Sanitario";Descripcion="Participantes del proyecto sanitario"},
    @{Nombre="G_Proyecto_Financiero";Descripcion="Participantes del proyecto financiero"},
    @{Nombre="G_Becarios";Descripcion="Todos los empleados en practicas"},

    @{Nombre="G_Becarios_Desarrollo";Descripcion="Becarios del departamento de Desarrollo"},
    @{Nombre="G_Becarios_Marketing";Descripcion="Becarios del departamento de Marketing"},
    @{Nombre="G_Becarios_Soporte";Descripcion="Becarios del departamento de Soporte"},

    @{Nombre="G_Politica_15";Descripcion="Cuentas sujetas a contrasenas de minimo 15 caracteres"},
    @{Nombre="G_Admin_Sistemas";Descripcion="Cuentas administrativas separadas del uso diario"}
)

# ----------------------------------------------------------
# FUNCIONES
# ----------------------------------------------------------

function Crear-OU {
    param(
        [string]$Nombre,
        [string]$Ruta
    )

    $DNObjetivo = "OU=$Nombre,$Ruta"

    $Existe = Get-ADOrganizationalUnit `
        -LDAPFilter "(distinguishedName=$DNObjetivo)" `
        -ErrorAction SilentlyContinue

    if (-not $Existe) {
        New-ADOrganizationalUnit `
            -Name $Nombre `
            -Path $Ruta `
            -ProtectedFromAccidentalDeletion $true

        Write-Host "OU creada: $DNObjetivo" -ForegroundColor Green
    }
    else {
        Write-Host "OU existente: $DNObjetivo" -ForegroundColor Yellow
    }

    return $DNObjetivo
}

function Crear-GrupoGlobal {
    param(
        [string]$Nombre,
        [string]$Descripcion,
        [string]$Ruta
    )

    # Se busca en todo el dominio: el nombre de un grupo es unico en el dominio.
    $Existe = Get-ADGroup `
        -Filter "SamAccountName -eq '$Nombre'" `
        -ErrorAction SilentlyContinue

    if (-not $Existe) {
        New-ADGroup `
            -Name $Nombre `
            -SamAccountName $Nombre `
            -GroupCategory Security `
            -GroupScope Global `
            -Path $Ruta `
            -Description $Descripcion

        Write-Host "Grupo creado: $Nombre" -ForegroundColor Green
    }
    elseif ($Existe.DistinguishedName -notlike "*,$Ruta") {
        Write-Host "Grupo existente FUERA de OU=Grupos: $($Existe.DistinguishedName)" -ForegroundColor Magenta
    }
    else {
        Write-Host "Grupo existente: $Nombre" -ForegroundColor Yellow
    }
}

# ----------------------------------------------------------
# 1. OU PRINCIPAL
# ----------------------------------------------------------

$Dominio = Get-ADDomain
$DN = $Dominio.DistinguishedName

Write-Host "Dominio detectado: $($Dominio.DNSRoot)" -ForegroundColor Cyan
Write-Host "DN: $DN" -ForegroundColor Cyan

Write-Host "`n===== 1. OU PRINCIPAL =====" -ForegroundColor Cyan

$OUPrincipal = Crear-OU -Nombre "CiberNova" -Ruta $DN

# ----------------------------------------------------------
# 2. OU GENERALES
# ----------------------------------------------------------

Write-Host "`n===== 2. OU GENERALES =====" -ForegroundColor Cyan

$OUUsuarios   = Crear-OU -Nombre "Usuarios" -Ruta $OUPrincipal
$OUGrupos     = Crear-OU -Nombre "Grupos" -Ruta $OUPrincipal
$OUEspeciales = Crear-OU -Nombre $NombreOUEspeciales -Ruta $OUPrincipal
$OUBajas      = Crear-OU -Nombre "Bajas" -Ruta $OUPrincipal
$OUEquipos    = Crear-OU -Nombre "Equipos" -Ruta $OUPrincipal
$OUServidores = Crear-OU -Nombre "Servidores" -Ruta $OUPrincipal

# ----------------------------------------------------------
# 3. OU DEPARTAMENTALES
# ----------------------------------------------------------

Write-Host "`n===== 3. OU DEPARTAMENTALES =====" -ForegroundColor Cyan

foreach ($Departamento in $Departamentos) {
    Crear-OU -Nombre $Departamento -Ruta $OUUsuarios | Out-Null
}

# ----------------------------------------------------------
# 4. OU DE CUENTAS ESPECIALES
# ----------------------------------------------------------

Write-Host "`n===== 4. OU CUENTAS ESPECIALES =====" -ForegroundColor Cyan

Crear-OU -Nombre "Administracion" -Ruta $OUEspeciales | Out-Null
Crear-OU -Nombre "Servicios" -Ruta $OUEspeciales | Out-Null

# ----------------------------------------------------------
# 4b. OU DE EQUIPOS (v2.1)
# ----------------------------------------------------------
# Una OU por sede para los puestos de trabajo y una para el equipo de
# recepcion (BCN-RECEPCION), que tendra GPO propias (perfil obligatorio).

Write-Host "`n===== 4b. OU EQUIPOS =====" -ForegroundColor Cyan

foreach ($Sede in @("Barcelona","Madrid","Valencia","Recepcion")) {
    Crear-OU -Nombre $Sede -Ruta $OUEquipos | Out-Null
}

# ----------------------------------------------------------
# 5. GRUPOS GLOBALES
# ----------------------------------------------------------

Write-Host "`n===== 5. GRUPOS GLOBALES =====" -ForegroundColor Cyan

foreach ($Grupo in $Grupos) {
    Crear-GrupoGlobal `
        -Nombre $Grupo.Nombre `
        -Descripcion $Grupo.Descripcion `
        -Ruta $OUGrupos
}

# ----------------------------------------------------------
# 6. RESUMEN
# ----------------------------------------------------------

Write-Host "`n===== 6. RESUMEN =====" -ForegroundColor Cyan

Write-Host "OU creadas bajo CiberNova:"
Get-ADOrganizationalUnit -Filter * -SearchBase $OUPrincipal -SearchScope Subtree |
    Select-Object Name,DistinguishedName |
    Format-Table -AutoSize

Write-Host "`nGrupos en OU=Grupos:"
Get-ADGroup -Filter * -SearchBase $OUGrupos |
    Select-Object Name,GroupScope,GroupCategory |
    Format-Table -AutoSize

Write-Host "`nOU Y GRUPOS FINALIZADOS. Siguiente paso: 02-alta-usuarios.ps1" -ForegroundColor Green
