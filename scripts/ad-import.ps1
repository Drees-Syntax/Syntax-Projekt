param(
  [Parameter(Mandatory = $true)] [string]$TargetDomainDN,
  [Parameter(Mandatory = $true)] [string]$BaseOuName,
  [Parameter(Mandatory = $true)] [string]$InDir,
  [Parameter(Mandatory = $true)] [string]$DefaultUserPassword
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

function Convert-DNToTarget {
  param([string]$SourceDN,[string]$SourceDomainDN,[string]$TargetDomainDN)
  return ($SourceDN -replace [regex]::Escape($SourceDomainDN) + '$', $TargetDomainDN)
}

$ousFile = Join-Path $InDir "ous.csv"
$groupsFile = Join-Path $InDir "groups.csv"
$usersFile = Join-Path $InDir "users.csv"
$membershipFile = Join-Path $InDir "memberships.csv"

if (!(Test-Path $ousFile) -or !(Test-Path $groupsFile) -or !(Test-Path $usersFile) -or !(Test-Path $membershipFile)) {
  throw "CSV-Dateien fehlen in $InDir"
}

# SourceDomainDN aus erstem Datensatz ableiten
$firstOu = Import-Csv $ousFile | Select-Object -First 1
if (-not $firstOu) { throw "ous.csv leer." }
$sourceDomainDN = ($firstOu.DistinguishedName -replace '^.*?(DC=.*)$','$1')

# Basis-OU sicherstellen
$baseTargetDn = "OU=$BaseOuName,$TargetDomainDN"
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$baseTargetDn)" -ErrorAction SilentlyContinue)) {
  New-ADOrganizationalUnit -Name $BaseOuName -Path $TargetDomainDN | Out-Null
}

# OUs anlegen (erst kurze DN, dann tiefer)
$ous = Import-Csv $ousFile | Sort-Object { ($_.DistinguishedName -split ',').Count }
foreach ($ou in $ous) {
  $targetDn = Convert-DNToTarget -SourceDN $ou.DistinguishedName -SourceDomainDN $sourceDomainDN -TargetDomainDN $TargetDomainDN
  if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$targetDn)" -ErrorAction SilentlyContinue)) {
    $name = ($targetDn -split ',')[0] -replace '^OU='
    $path = ($targetDn -split ',',2)[1]
    New-ADOrganizationalUnit -Name $name -Path $path | Out-Null
  }
}

# Gruppen anlegen
$groups = Import-Csv $groupsFile
foreach ($g in $groups) {
  if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($g.SamAccountName)'" -ErrorAction SilentlyContinue)) {
    $targetDn = Convert-DNToTarget -SourceDN $g.DistinguishedName -SourceDomainDN $sourceDomainDN -TargetDomainDN $TargetDomainDN
    $name = ($targetDn -split ',')[0] -replace '^CN='
    $path = ($targetDn -split ',',2)[1]
    New-ADGroup `
      -Name $name `
      -SamAccountName $g.SamAccountName `
      -GroupScope $g.GroupScope `
      -GroupCategory $g.GroupCategory `
      -Path $path `
      -Description $g.Description | Out-Null
  }
}

# User anlegen
$users = Import-Csv $usersFile
$secPw = ConvertTo-SecureString $DefaultUserPassword -AsPlainText -Force

foreach ($u in $users) {
  if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue)) {
    $targetDn = Convert-DNToTarget -SourceDN $u.DistinguishedName -SourceDomainDN $sourceDomainDN -TargetDomainDN $TargetDomainDN
    $name = ($targetDn -split ',')[0] -replace '^CN='
    $path = ($targetDn -split ',',2)[1]

    New-ADUser `
      -Name $name `
      -SamAccountName $u.SamAccountName `
      -UserPrincipalName $u.UserPrincipalName `
      -GivenName $u.GivenName `
      -Surname $u.Surname `
      -DisplayName $u.DisplayName `
      -Description $u.Description `
      -Path $path `
      -Enabled ([System.Convert]::ToBoolean($u.Enabled)) `
      -AccountPassword $secPw `
      -ChangePasswordAtLogon $true | Out-Null
  }
}

# Mitgliedschaften setzen
$memberships = Import-Csv $membershipFile
foreach ($m in $memberships) {
  $memberTargetDn = Convert-DNToTarget -SourceDN $m.MemberDN -SourceDomainDN $sourceDomainDN -TargetDomainDN $TargetDomainDN
  $memberObj = Get-ADObject -LDAPFilter "(distinguishedName=$memberTargetDn)" -ErrorAction SilentlyContinue
  if ($memberObj) {
    Add-ADGroupMember -Identity $m.GroupSam -Members $memberObj.DistinguishedName -ErrorAction SilentlyContinue
  }
}

Write-Host "Import fertig nach $TargetDomainDN"
