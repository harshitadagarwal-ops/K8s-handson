# Shared helpers for the PowerShell scripts (dot-sourced, not run directly).
$ErrorActionPreference = 'Stop'

$Root  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$TfDir = Join-Path $Root 'terraform\envs\dev'

# Native commands do not throw on failure in PowerShell; check the exit code.
function Invoke-Checked {
    param([string]$Cmd, [string[]]$CmdArgs)
    & $Cmd @CmdArgs
    if ($LASTEXITCODE -ne 0) { throw "$Cmd $($CmdArgs -join ' ') failed with exit code $LASTEXITCODE" }
}

function Get-TfOutput {
    param([string]$Name)
    Push-Location $TfDir
    try {
        $value = terraform output -raw $Name
        if ($LASTEXITCODE -ne 0) { throw "terraform output $Name failed. Did you run terraform apply?" }
        return ($value | Out-String).Trim()
    }
    finally { Pop-Location }
}
