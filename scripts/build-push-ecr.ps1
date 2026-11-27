# Build the backend and frontend images and push them to ECR.
# PowerShell version of build-push-ecr.sh. Run `terraform apply` first.
#   $env:IMAGE_TAG = 'v1'; .\scripts\build-push-ecr.ps1    # optional fixed tag
# ECR tags are immutable, so every build needs a new tag. Default: git short SHA
# (plus a timestamp if the working tree is dirty). Saved in .image-tag.
. (Join-Path $PSScriptRoot 'common.ps1')

$Region       = Get-TfOutput 'region'
$Registry     = Get-TfOutput 'ecr_registry'
$BackendRepo  = Get-TfOutput 'ecr_backend_repo'
$FrontendRepo = Get-TfOutput 'ecr_frontend_repo'

if ($env:IMAGE_TAG) {
    $Tag = $env:IMAGE_TAG
}
else {
    $Tag = (git -C $Root rev-parse --short HEAD | Out-String).Trim()
    if (git -C $Root status --porcelain) { $Tag = "$Tag-$(Get-Date -Format yyyyMMddHHmmss)" }
}

Write-Host "Logging in to $Registry"
# Run the pipe inside cmd.exe: Windows PowerShell 5 re-encodes piped text and adds
# a line break, which makes ECR reject the token ("400 Bad Request").
cmd /c "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry"
if ($LASTEXITCODE -ne 0) { throw 'ECR login failed' }

Write-Host "Building and pushing tag: $Tag"
Invoke-Checked docker @('build', '--platform', 'linux/amd64', '-t', "${BackendRepo}:$Tag", (Join-Path $Root 'app\backend'))
Invoke-Checked docker @('build', '--platform', 'linux/amd64', '-t', "${FrontendRepo}:$Tag", (Join-Path $Root 'app\frontend'))
Invoke-Checked docker @('push', "${BackendRepo}:$Tag")
Invoke-Checked docker @('push', "${FrontendRepo}:$Tag")

Set-Content -Path (Join-Path $Root '.image-tag') -Value $Tag -NoNewline
Write-Host 'Done. Next: .\scripts\deploy-eks.ps1'
