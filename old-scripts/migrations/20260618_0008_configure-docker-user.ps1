#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

$groupName = 'docker-users'
$group = Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue
if (-not $group) {
    throw "Local group '$groupName' was not found. Re-run after Docker Desktop finishes installing."
}

$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$memberName = $identity.Name
$memberSid = $identity.User.Value

$members = @(Get-LocalGroupMember -Group $groupName -ErrorAction SilentlyContinue)
$alreadyMember = $false
foreach ($member in $members) {
    if (($member.Name -eq $memberName) -or ($member.SID.Value -eq $memberSid)) {
        $alreadyMember = $true
        break
    }
}

if (-not $alreadyMember) {
    Add-LocalGroupMember -Group $groupName -Member $memberName
    Write-Information -MessageData "Added $memberName to $groupName. Sign out or reboot before using Docker without elevation." -InformationAction Continue
} else {
    Write-Information -MessageData "$memberName is already in $groupName." -InformationAction Continue
}
