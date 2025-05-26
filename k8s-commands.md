

eval $(minikube docker-env)      # Point Docker CLI to Minikube's internal Docker
docker build --no-cache -t gandalf-web:latest .

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

kubectl get pods

sudo apt update
sudo apt install nginx -y

sudo nano /etc/nginx/sites-available/default
sudo nginx -t       # Validate again
sudo systemctl restart nginx

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
-
helm install hello prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.maximumStartupDurationSeconds=300

kubectl get pods -n monitoring

if needed 
kubectl patch svc gandalf-grafana -n monitoring -p '{
  "spec": {
    "type": "NodePort",
    "ports": [{
      "port": 80,
      "targetPort": 3000,
      "nodePort": 30000,
      "protocol": "TCP"
    }]
  }
}'




kubectl patch svc gandalf-grafana -n monitoring -p '{
  "spec": {
    "type": "ClusterIP",
    "ports": [{
      "port": 80,
      "targetPort": 3000,
      "protocol": "TCP"
    }]
  }
}'


# Build image (no cache)
docker build --no-cache -t gandalf-web:0.3 .

# Tag for Docker Hub
docker tag gandalf-web:0.3 \
  $DOCKERHUB_USER/gandalf-web:0.3

# Log in to Docker Hub
docker login

# Push tags
docker push $DOCKERHUB_USER/gandalf-web:0.3
docker push $DOCKERHUB_USER/gandalf-web:latest


# Apply all manifests
kubectl apply -f k8s/

# Check pods/services
kubectl get pods           -n default
kubectl get svc            -n default
kubectl get servicemonitor -n monitoring

# Describe & debug
kubectl describe pod <pod-name>         # view events, state
kubectl logs <pod-name>  -c web         # container logs
kubectl exec -it <pod> -- /bin/sh       # into container

# Port-forward local testing
kubectl port-forward svc/gandalf-web 8080:80    # app
kubectl port-forward svc/prometheus 9090:9090  -n monitoring

# Rolling updates & rollbacks
kubectl set image deployment/gandalf-web web=$DOCKERHUB_USER/gandalf-web:0.4
kubectl rollout status deployment/gandalf-web
kubectl rollout undo   deployment/gandalf-web

Here’s a consolidated, labeled reference of all the commands we’ll need across the full stack—Terraform, Docker, Kubernetes/Minikube, Helm, Prometheus & Grafana, CI/CD, and VM bootstrap. Feel free to copy this into your docs or cheat-sheet.

---

## 🌐 1. Infrastructure as Code (Terraform)

```bash
# Initialize & download providers
terraform init

# Format your .tf files
terraform fmt

# Validate syntax and catch errors
terraform validate

# See what will change
terraform plan

# Apply changes (with auto-approve in CI)
terraform apply
terraform apply -auto-approve

# Apply with inline vars (e.g. from .env or CI)
terraform apply \
  -var "dockerhub_user=$DOCKERHUB_USER" \
  -var "my_ip=$(curl -s ifconfig.me)/32"

# Destroy everything (clean-up)
terraform destroy -auto-approve
```

---

## 🐳 2. Container Build & Push (Docker / Docker Hub)

```bash
# Build image (no cache)
docker build --no-cache -t gandalf-web:0.3 .

# Tag for Docker Hub
docker tag gandalf-web:0.3 \
  $DOCKERHUB_USER/gandalf-web:0.3

# Log in to Docker Hub
docker login

# Push tags
docker push $DOCKERHUB_USER/gandalf-web:0.3
docker push $DOCKERHUB_USER/gandalf-web:latest
```

---

## 3. Local Dev with Minikube

```bash
# Start cluster (Docker driver)
minikube start --driver=docker

# Load a local image into Minikube
minikube image load gandalf-web:0.3

# List nodes & IP
kubectl get nodes -o wide

# Expose service via NodePort
minikube service gandalf-web --url

# Tunnel LoadBalancer IPs (Linux/macOS)
sudo minikube tunnel
```

---

## 🧰 4. Kubernetes CLI (kubectl)

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check pods/services
kubectl get pods           -n default
kubectl get svc            -n default
kubectl get servicemonitor -n monitoring

# Describe & debug
kubectl describe pod <pod-name>         # view events, state
kubectl logs <pod-name>  -c web         # container logs
kubectl exec -it <pod> -- /bin/sh       # into container

# Port-forward local testing
kubectl port-forward svc/gandalf-web 8080:80    # app
kubectl port-forward svc/prometheus 9090:9090  -n monitoring

# Rolling updates & rollbacks
kubectl set image deployment/gandalf-web web=$DOCKERHUB_USER/gandalf-web:0.4
kubectl rollout status deployment/gandalf-web
kubectl rollout undo   deployment/gandalf-web
```

---

## 📦 5. Package & Deploy with Helm

```bash
# Add & update repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Lint your chart
helm lint gandalf-chart

# Package chart (CI/CD)
helm dependency update gandalf-chart
helm package gandalf-chart --app-version v0.3 --version v0.3

# Install or upgrade
helm install  gandalf ./gandalf-chart --namespace default --create-namespace
helm upgrade  gandalf ./gandalf-chart \
  --set image.repository=$DOCKERHUB_USER/gandalf-web \
  --set image.tag=0.3

# Rollback
helm rollback gandalf 1
```

---

## 📊 6. Prometheus & Grafana

```bash
# Port-forward to access UIs locally
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
kubectl -n monitoring port-forward svc/monitoring-grafana                  3000:3000

# Prometheus API queries
curl 'http://localhost:9090/api/v1/query?query=gandalf_requests_total'
curl 'http://localhost:9090/api/v1/query?query=colombo_requests_total'

# Import a dashboard in Grafana (ID 1860 = “Prometheus stats”)
# 1) Log in at http://localhost:3000 (admin/prom-operator)
# 2) Dashboards → + Import → enter 1860 → Load
```

---

```


---

## 🔧 9. Troubleshooting & Tips

```bash
# Show cloud-init logs on VM
sudo tail -n 200 /var/log/cloud-init-output.log

# Verify ServiceMonitor labels & scrape status
kubectl get servicemonitor -n monitoring
kubectl get endpoints -n monitoring

# If a ServiceMonitor isn’t picked up:
kubectl delete servicemonitor gandalf-monitor -n monitoring
helm upgrade --install gandalf ./gandalf-chart

# If Minikube LoadBalancer IP isn’t reachable:
minikube tunnel       # on Linux/macOS
minikube service ...  # NodePort fallback
```

---

Keep this sheet handy, and you’ll have every step—from **infra provisioning** to **app deployment**, **observability**, and **CI/CD**—at your fingertips. 🚀
