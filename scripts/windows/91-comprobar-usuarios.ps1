# ==========================================================
# CIBERNOVA - 91. COMPROBAR USUARIOS (para capturas)
# Version: 1.0 (16/11/2026)
# Solo lee; no cambia nada. Fichero 100% ASCII.
#   powershell -ExecutionPolicy Bypass -File .\91-comprobar-usuarios.ps1
#   powershell -ExecutionPolicy Bypass -File .\91-comprobar-usuarios.ps1 -Lista   (ademas abre la lista completa)
# ==========================================================

param([switch]$Lista)

Import-Module ActiveDirectory

$base = "OU=CiberNova," + (Get-ADDomain).DistinguishedName

Write-Host "`n=== EMPLEADOS POR DEPARTAMENTO ===" -ForegroundColor Cyan
Get-ADUser -Filter * -SearchBase "OU=Usuarios,$base" -Properties CanonicalName |
    Group-Object { ($PSItem.CanonicalName -split '/')[3] } |
    Sort-Object Name |
    Format-Table @{n='Departamento';e={$PSItem.Name}}, @{n='Usuarios';e={$PSItem.Count}} -AutoSize
"TOTAL EMPLEADOS: " + @(Get-ADUser -Filter * -SearchBase "OU=Usuarios,$base").Count

Write-Host "`n=== BECARIOS ===" -ForegroundColor Cyan
Get-ADGroupMember -Identity "G_Becarios" |
    Get-ADUser -Properties AccountExpirationDate, MemberOf |
    Format-Table SamAccountName,
        @{n='Caduca';e={$PSItem.AccountExpirationDate}},
        @{n='Grupos';e={ ($PSItem.MemberOf | ForEach-Object { ($PSItem -split ',')[0] -replace 'CN=' }) -join ', ' }} -AutoSize -Wrap

Write-Host "`n=== CUENTAS ADM. Y ESPECIALES ===" -ForegroundColor Cyan
Get-ADUser -Filter * -SearchBase "OU=Cuentas especiales,$base" -SearchScope Subtree `
        -Properties CannotChangePassword, PasswordNeverExpires, LogonWorkstations, AccountExpirationDate |
    Sort-Object SamAccountName |
    Format-Table SamAccountName, Enabled,
        @{n='NoCambiaPwd';e={$PSItem.CannotChangePassword}},
        @{n='PwdNoCaduca';e={$PSItem.PasswordNeverExpires}},
        @{n='SoloEquipo';e={$PSItem.LogonWorkstations}},
        @{n='Caduca';e={$PSItem.AccountExpirationDate}} -AutoSize

if ($Lista) {
    Get-ADUser -Filter * -SearchBase "OU=Usuarios,$base" -Properties Department, Title, Office |
        Select-Object SamAccountName, Name, Department, Title, Office, Enabled |
        Sort-Object Department, SamAccountName |
        Out-GridView -Title "CiberNova - Empleados"
}
