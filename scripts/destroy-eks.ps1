# Tear everything down, in the right order (PowerShell version of destroy-eks.sh).
# The Network Load Balancer is created by Kubernetes, not Terraform. If it is
# still alive, `terraform destroy` hangs on the VPC. So delete the namespace
# first (this removes the load balancer), then destroy the infrastructure.
#   .\scripts\destroy-eks.ps1                 # asks for confirmation
#   .\scripts\destroy-eks.ps1 -AutoApprove
param([switch]$AutoApprove)
. (Join-Path $PSScriptRoot 'common.ps1')

$Region  = Get-TfOutput 'region'
$Cluster = Get-TfOutput 'cluster_name'

$reachable = $false
try {
    $ErrorActionPreference = 'Continue'   # stderr from failed probes must not abort the script
    aws eks update-kubeconfig --region $Region --name $Cluster 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        kubectl get ns demo 2>$null | Out-Null
        $reachable = ($LASTEXITCODE -eq 0)
    }
}
finally { $ErrorActionPreference = 'Stop' }

if ($reachable) {
    Write-Host 'Deleting namespace demo (removes the load balancer)...'
    Invoke-Checked kubectl @('delete', 'ns', 'demo', '--wait', '--timeout=10m')
}
else {
    Write-Warning 'Could not reach the cluster (or namespace is already gone). If a load balancer still exists, delete it in the EC2 console or the VPC destroy will hang.'
}

Push-Location $TfDir
try {
    $tfArgs = @('destroy')
    if ($AutoApprove) { $tfArgs += '-auto-approve' }
    Invoke-Checked terraform $tfArgs
}
finally { Pop-Location }
