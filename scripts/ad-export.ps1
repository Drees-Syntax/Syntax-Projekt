param(
  [Parameter(Mandatory = $true)] [string]$SourceDomainDN,
  [Parameter(Mandatory = $true)] [string]$BaseOuName,
  [Parameter(Mandatory = $true)] [string]$OutDir
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$baseDn = "OU=$BaseOuName,$SourceDomainDN"

# OUs (inkl. Unter-OUs)
Get-ADOrganizationalUnit -Filter * -SearchBase $baseDn -SearchScope Subtree |
  Select-Object Name, DistinguishedName |
  Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutDir "ous.csv")

# Gruppen
Get-ADGroup -Filter * -SearchBase $baseDn -SearchScope Subtree -Properties GroupScope,GroupCategory,Description |
  Select-Object Name,SamAccountName,DistinguishedName,GroupScope,GroupCategory,Description |
  Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutDir "groups.csv")

# Benutzer
Get-ADUser -Filter * -SearchBase $baseDn -SearchScope Subtree -Properties GivenName,Surname,DisplayName,UserPrincipalName,Enabled,Description |
  Select-Object Name,SamAccountName,DistinguishedName,GivenName,Surname,DisplayName,UserPrincipalName,Enabled,Description |
  Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutDir "users.csv")

# Mitgliedschaften (nur Gruppen unterhalb Base-OU)
$memberships = foreach ($g in (Import-Csv (Join-Path $OutDir "groups.csv"))) {
  $members = Get-ADGroupMember -Identity $g.SamAccountName -Recursive:$false -ErrorAction SilentlyContinue
  foreach ($m in $members) {
    [PSCustomObject]@{
      GroupSam = $g.SamAccountName
      MemberDN = $m.DistinguishedName
      MemberObjectClass = $m.objectClass
    }
  }
}
$memberships | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutDir "memberships.csv")

Write-Host "Export fertig: $OutDir"
