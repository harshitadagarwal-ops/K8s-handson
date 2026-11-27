# Deploy the app to the EKS cluster created by Terraform.
# PowerShell version of deploy-eks.sh:
#  1. point kubectl at the cluster
#  2. create the namespace, then app-config (RDS host) and app-secret (RDS
#     credentials from AWS Secrets Manager, piped via stdin, never written to disk)
#  3. render k8s/overlays/eks with the real ECR image names and apply it
. (Join-Path $PSScriptRoot 'common.ps1')

$Region       = Get-TfOutput 'region'
$Cluster      = Get-TfOutput 'cluster_name'
$BackendRepo  = Get-TfOutput 'ecr_backend_repo'
$FrontendRepo = Get-TfOutput 'ecr_frontend_repo'
$DbHost       = Get-TfOutput 'rds_address'
$DbName       = Get-TfOutput 'rds_db_name'
$SecretArn    = Get-TfOutput 'rds_secret_arn'

if ($env:IMAGE_TAG) { $Tag = $env:IMAGE_TAG }
else { $Tag = (Get-Content (Join-Path $Root '.image-tag') -Raw).Trim() }

Invoke-Checked aws @('eks', 'update-kubeconfig', '--region', $Region, '--name', $Cluster)

kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'creating namespace failed' }

$secretJson = aws secretsmanager get-secret-value --region $Region --secret-id $SecretArn --query SecretString --output text
if ($LASTEXITCODE -ne 0) { throw 'reading the RDS secret failed' }
$cred = ($secretJson | Out-String) | ConvertFrom-Json

$manifest = @{
    apiVersion = 'v1'
    kind       = 'List'
    items      = @(
        @{
            apiVersion = 'v1'; kind = 'ConfigMap'
            metadata   = @{ name = 'app-config'; namespace = 'demo' }
            data       = @{ DB_HOST = $DbHost; DB_NAME = $DbName }
        },
        @{
            apiVersion = 'v1'; kind = 'Secret'; type = 'Opaque'
            metadata   = @{ name = 'app-secret'; namespace = 'demo' }
            stringData = @{ DB_USER = $cred.username; DB_PASSWORD = $cred.password }
        }
    )
}
$manifest | ConvertTo-Json -Depth 10 | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'applying config/secret failed' }

Write-Host "Deploying image tag: $Tag"
$yaml = (kubectl kustomize (Join-Path $Root 'k8s\overlays\eks')) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'kustomize build failed' }
$yaml = $yaml.Replace('ECR_BACKEND_REPO', $BackendRepo).Replace('ECR_FRONTEND_REPO', $FrontendRepo).Replace('IMAGE_TAG', $Tag)
$yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'applying manifests failed' }

Invoke-Checked kubectl @('-n', 'demo', 'rollout', 'status', 'deploy/backend', '--timeout=300s')
Invoke-Checked kubectl @('-n', 'demo', 'rollout', 'status', 'deploy/frontend', '--timeout=300s')

Write-Host 'Waiting for the load balancer hostname (can take 2-3 minutes)...'
for ($i = 0; $i -lt 30; $i++) {
    $lb = kubectl -n demo get svc frontend -o 'jsonpath={.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($lb) {
        Write-Host "App URL: http://$lb   (DNS may need another minute to resolve)"
        return
    }
    Start-Sleep -Seconds 10
}
Write-Host 'Load balancer not ready yet. Check: kubectl -n demo get svc frontend'
