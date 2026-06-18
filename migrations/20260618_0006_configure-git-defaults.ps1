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
    @{ key = 'pull.rebase'; value = 'false' },
    @{ key = 'credential.helper'; value = 'manager' }
)

foreach ($setting in $settings) {
    Invoke-NativeCommand `
        -Label "Setting git $($setting.key)" `
        -FilePath git `
        -ArgumentList @('config', '--global', $setting.key, $setting.value) | Out-Null
}

Write-Information -MessageData "Git defaults configured. Set user.name and user.email manually per identity." -InformationAction Continue
