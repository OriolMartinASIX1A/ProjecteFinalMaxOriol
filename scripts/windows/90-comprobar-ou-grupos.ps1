# ==========================================================
# CIBERNOVA - 90. COMPROBAR OU Y GRUPOS (para capturas)
# Version: 1.0 (16/11/2026)
# Solo lee; no cambia nada. Fichero 100% ASCII.
#   powershell -ExecutionPolicy Bypass -File .\90-comprobar-ou-grupos.ps1
# ==========================================================

Import-Module ActiveDirectory

$base = "OU=CiberNova," + (Get-ADDomain).DistinguishedName

Write-Host "`n=== ESTRUCTURA DE OU ===" -ForegroundColor Cyan
Get-ADOrganizationalUnit -Filter * -SearchBase $base -Properties CanonicalName |
    Sort-Object CanonicalName |
    ForEach-Object {
        $nivel = ($PSItem.CanonicalName -split '/').Count - 2
        ("    " * $nivel) + "|-- " + $PSItem.Name
    }
"TOTAL OU: " + @(Get-ADOrganizationalUnit -Filter * -SearchBase $base).Count

Write-Host "`n=== GRUPOS ===" -ForegroundColor Cyan
Get-ADGroup -Filter * -SearchBase "OU=Grupos,$base" |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            Grupo    = $PSItem.Name
            Ambito   = $PSItem.GroupScope
            Tipo     = $PSItem.GroupCategory
            Miembros = @(Get-ADGroupMember -Identity $PSItem).Count
        }
    } |
    Format-Table -AutoSize
"TOTAL GRUPOS: " + @(Get-ADGroup -Filter * -SearchBase "OU=Grupos,$base").Count

Write-Host "`n=== MIEMBROS DE ADMINS. DEL DOMINIO ===" -ForegroundColor Cyan
Get-ADGroupMember -Identity ((Get-ADDomain).DomainSID.Value + "-512") |
    Format-Table Name, ObjectClass -AutoSize
