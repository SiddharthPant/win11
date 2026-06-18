# Shared helpers for setup migrations.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [string[]] $ArgumentList = @(),

        [int[]] $AllowedExitCodes = @(0),

        [string] $Label,

        [switch] $ContinueOnError
    )

    if ($Label) {
        Write-Information -MessageData "$Label ..." -InformationAction Continue
    }

    & $FilePath @ArgumentList
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

    if ($AllowedExitCodes -notcontains $exitCode) {
        $displayName = if ($Label) { $Label } else { $FilePath }
        $message = "$displayName failed with exit code $exitCode."
        if ($ContinueOnError) {
            Write-Information -MessageData $message -InformationAction Continue
        } else {
            throw $message
        }
    }

    return $exitCode
}

function Wait-Winget {
    param(
        [int] $Attempts = 30,
        [int] $DelaySeconds = 10
    )

    Write-Information -MessageData "Waiting for winget to become available..." -InformationAction Continue
    for ($i = 0; $i -lt $Attempts; $i++) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            return
        }

        Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "winget is unavailable. Open Microsoft Store, let App Installer update, then re-run migrations."
}

function Test-WingetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id
    )

    $output = & winget list --id $Id -e --disable-interactivity 2>&1
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    $text = $output | Out-String
    $escapedId = [regex]::Escape($Id)

    if ($text -match 'No installed package found|No package found') {
        return $false
    }

    if ($exitCode -eq -1978335211) {
        return $false
    }

    if ($exitCode -ne 0) {
        throw "Checking installed package $Id failed with exit code $exitCode.`n$text"
    }

    if ($text -match "(?im)(^|\s)$escapedId(\s|$)") {
        return $true
    }

    return $false
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id,

        [string] $Source = 'winget',

        [string] $Name = $Id
    )

    if (Test-WingetPackageInstalled -Id $Id) {
        Write-Information -MessageData "$Name is already installed; skipping." -InformationAction Continue
        return
    }

    Invoke-NativeCommand `
        -Label "Installing $Name" `
        -FilePath winget `
        -ArgumentList @('install', '--id', $Id, '-e', '--source', $Source, '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') `
        -AllowedExitCodes @(0, -1978334963, -1978335135) | Out-Null
}
