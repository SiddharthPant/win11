#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not available. Re-run after the Git.Git winget migration succeeds."
}

$settings = @(
    @{ key = 'init.defaultBranch'; value = 'main' },
    @{ key = 'core.autocrlf'; value = 'false' },
    @{ key = 'core.longpaths'; value = 'true' },
    @{ key = 'fetch.prune'; value = 'true' },
    @{ key = 'pull.ff'; value = 'only' },
    @{ key = 'credential.helper'; value = 'manager' }
)

foreach ($setting in $settings) {
    $currentValue = & git config --global --get $setting.key 2>$null
    if (($LASTEXITCODE -eq 0) -and ($currentValue -eq $setting.value)) {
        Write-Information -MessageData "Git $($setting.key) is already $($setting.value); skipping." -InformationAction Continue
        continue
    }

    Invoke-NativeCommand `
        -Label "Setting git $($setting.key)" `
        -FilePath git `
        -ArgumentList @('config', '--global', $setting.key, $setting.value) | Out-Null
}

Write-Information -MessageData "Git defaults configured. Set user.name and user.email manually per identity." -InformationAction Continue
