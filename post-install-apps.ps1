<#
  Compatibility wrapper.

  The post-install flow now lives in migrations/. After first boot, run
  run-migrations.ps1 directly; this script is kept so old notes/shortcuts do the
  same thing.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch] $List
)

$ErrorActionPreference = 'Stop'

$runner = Join-Path $PSScriptRoot 'run-migrations.ps1'
if (-not (Test-Path $runner)) {
    throw "Migration runner not found: $runner"
}

if ($List) {
    & $runner -List
} else {
    & $runner
}
