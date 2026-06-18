#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

$windowsUpdateKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$autoUpdateKey = Join-Path $windowsUpdateKey 'AU'

New-Item -Path $windowsUpdateKey -Force | Out-Null
New-Item -Path $autoUpdateKey -Force | Out-Null

# Microsoft documents these active-hours values under HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate.
Set-ItemProperty -Path $windowsUpdateKey -Name 'SetActiveHours' -Type DWord -Value 1
Set-ItemProperty -Path $windowsUpdateKey -Name 'ActiveHoursStart' -Type DWord -Value 8
Set-ItemProperty -Path $windowsUpdateKey -Name 'ActiveHoursEnd' -Type DWord -Value 23

# Avoid surprise restarts while the primary user is signed in.
Set-ItemProperty -Path $autoUpdateKey -Name 'NoAutoRebootWithLoggedOnUsers' -Type DWord -Value 1

Write-Information -MessageData "Windows Update policy configured: active hours 08:00-23:00 and no auto-reboot with logged-on users." -InformationAction Continue
