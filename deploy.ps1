$ErrorActionPreference = "Stop"

$PROJECT_ID = gcloud config get-value project
$REGION = "europe-west1"
$REGISTRY = "$REGION-docker.pkg.dev/$PROJECT_ID/pokereval"

Write-Host "Project ID: $PROJECT_ID"
Write-Host "Region: $REGION"
Write-Host "Registry: $REGISTRY"

# 1. Create Artifact Registry (ignore error if it already exists)
Write-Host "`n--- Creating Artifact Registry ---"
try {
    gcloud artifacts repositories create pokereval --repository-format=docker --location=$REGION 2>$null
} catch {
    Write-Host "Repository might already exist, continuing..."
}

# 2. Configure Docker authentication
Write-Host "`n--- Configuring Docker authentication ---"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

# 3. Build & push backend
Write-Host "`n--- Building and pushing backend image ---"
docker build --platform linux/amd64 -t $REGISTRY/backend:latest -f backend/Dockerfile .
docker push $REGISTRY/backend:latest

# 4. Create GKE cluster
Write-Host "`n--- Creating GKE cluster (this will take a while) ---"
try {
    gcloud container clusters create-auto pokereval-cluster --location=$REGION
} catch {
    Write-Host "Cluster might already exist, continuing..."
}
gcloud container clusters get-credentials pokereval-cluster --location=$REGION

# 5. Substitute image references in K8s manifests
Write-Host "`n--- Updating Kubernetes manifests ---"
Get-ChildItem -Path "k8s\*.yaml" | ForEach-Object {
    (Get-Content $_.FullName) -replace "REGION-docker.pkg.dev/PROJECT_ID/pokereval", $REGISTRY | Set-Content $_.FullName
}

# 6. Deploy Backend & related manifests
Write-Host "`n--- Deploying Backend and Ingress ---"
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/backend-hpa.yaml

Write-Host "`n--- Waiting for Ingress IP to be assigned (this may take a few minutes) ---"
$IngressIP = ""
while ([string]::IsNullOrWhiteSpace($IngressIP)) {
    Start-Sleep -Seconds 10
    $IngressIP = kubectl get ingress pokereval-ingress -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
    Write-Host "Waiting..."
}

Write-Host "`nIngress IP assigned: $IngressIP"
$BACKEND_URL = "http://$IngressIP"

# 7. Build & push frontend with real IP
Write-Host "`n--- Building and pushing frontend image with BACKEND_URL=$BACKEND_URL ---"
docker build --platform linux/amd64 --build-arg BACKEND_URL=$BACKEND_URL -t $REGISTRY/frontend:latest ./frontend
docker push $REGISTRY/frontend:latest

# 8. Restart frontend deployment
Write-Host "`n--- Restarting frontend deployment to pick up new image ---"
kubectl rollout restart deployment/pokereval-frontend

Write-Host "`n=== Deployment Complete ===`n"
Write-Host "You can access your application at: http://$IngressIP"
