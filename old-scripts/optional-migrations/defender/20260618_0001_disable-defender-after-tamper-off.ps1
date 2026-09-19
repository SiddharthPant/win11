#Requires -Version 5.1
#Requires -RunAsAdministrator

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repoRoot 'migrations') '_helpers.ps1')

if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
    throw "Microsoft Defender PowerShell cmdlets are not available on this system."
}

$status = Get-MpComputerStatus
if ($status.PSObject.Properties.Name -contains 'IsTamperProtected') {
    if ($status.IsTamperProtected) {
        throw "Tamper Protection is still on. Turn it off in Windows Security, then re-run this optional migration."
    }
}

$defenderPolicyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
$realTimePolicyKey = Join-Path $defenderPolicyKey 'Real-Time Protection'

New-Item -Path $defenderPolicyKey -Force | Out-Null
New-Item -Path $realTimePolicyKey -Force | Out-Null

Set-ItemProperty -Path $defenderPolicyKey -Name 'DisableAntiSpyware' -Type DWord -Value 1
Set-ItemProperty -Path $realTimePolicyKey -Name 'DisableRealtimeMonitoring' -Type DWord -Value 1
Set-ItemProperty -Path $realTimePolicyKey -Name 'DisableBehaviorMonitoring' -Type DWord -Value 1
Set-ItemProperty -Path $realTimePolicyKey -Name 'DisableOnAccessProtection' -Type DWord -Value 1
Set-ItemProperty -Path $realTimePolicyKey -Name 'DisableScanOnRealtimeEnable' -Type DWord -Value 1

Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableScriptScanning $true
Set-MpPreference -DisableArchiveScanning $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableScheduledScan $true
Set-MpPreference -MAPSReporting Disabled
Set-MpPreference -SubmitSamplesConsent NeverSend

$defenderTasks = @(
    'Windows Defender Cache Maintenance',
    'Windows Defender Cleanup',
    'Windows Defender Scheduled Scan',
    'Windows Defender Verification'
)

foreach ($taskName in $defenderTasks) {
    $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender\' -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.State -eq 'Disabled') {
            Write-Information -MessageData "Scheduled task already disabled: $taskName" -InformationAction Continue
        } else {
            $task | Disable-ScheduledTask | Out-Null
            Write-Information -MessageData "Disabled scheduled task: $taskName" -InformationAction Continue
        }
    }
}

Invoke-NativeCommand -Label "Refreshing policy" -FilePath gpupdate -ArgumentList @('/force') | Out-Null

$finalStatus = Get-MpComputerStatus
$finalStatus |
    Select-Object RealTimeProtectionEnabled, AntivirusEnabled, BehaviorMonitorEnabled, IsTamperProtected |
    Format-List

Write-Information -MessageData "Defender disable automation applied. Reboot, then verify with Get-MpComputerStatus." -InformationAction Continue
