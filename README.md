Below is a drop-in replacement for your manifests that **removes MetalLB**, uses **NodePort** (so you can hit `<ELASTIC-IP>:<NODE-PORT>`), and leans on an **Elastic IP** you’ve already attached to your VM.  You can then hit:

* `http://<ELASTIC-IP>:30080/gandalf`
* `http://<ELASTIC-IP>:30080/colombo`
* `http://<ELASTIC-IP>:30080/metrics`
* `http://<ELASTIC-IP>:30090`  (Prometheus UI)
* `http://<ELASTIC-IP>:30100`  (Grafana UI — default “Home” dashboard)

---

### 1. `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gandalf-web
  labels:
    app: gandalf-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gandalf-web
  template:
    metadata:
      labels:
        app: gandalf-web
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
        - name: web
          image: YOUR_DOCKERHUB_USER/gandalf-web:YOUR_TAG
          ports:
            - containerPort: 80
```

---

### 2. `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: gandalf-web
  labels:
    app: gandalf-web
spec:
  type: NodePort
  selector:
    app: gandalf-web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
      protocol: TCP
```

---

### 3. `servicemonitor.yaml` (unchanged)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gandalf-monitor
  namespace: monitoring
  labels:
    app: gandalf-web
spec:
  selector:
    matchLabels:
      app: gandalf-web
  namespaceSelector:
    matchNames:
      - default
  endpoints:
    - port: 80
      path: /metrics
      interval: 15s
```

---

### 4. Helm install for Prometheus & Grafana (NodePort)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.service.type=NodePort         \
  --set prometheus.service.nodePort=30090         \
  --set grafana.service.type=NodePort            \
  --set grafana.service.nodePort=30100
```

---

### 5. Security Group / Firewall

Make sure your EC2 security group allows inbound:

* TCP 30080  → your web app
* TCP 30090  → Prometheus
* TCP 30100  → Grafana

---

### 6. Apply & Verify

```bash
kubectl apply -f deployment.yaml -f service.yaml
kubectl apply -f servicemonitor.yaml
```

Wait until pods are ready, then curl:

```bash
curl http://<ELASTIC-IP>:30080/gandalf
curl http://<ELASTIC-IP>:30080/colombo
curl http://<ELASTIC-IP>:30080/metrics
```

Port-forward if you ever need to:

```bash
kubectl port-forward svc/gandalf-web 8080:80
```

---

### 7. Grafana Default View

Once Grafana is up at `http://<ELASTIC-IP>:30100` (login `admin/prom-operator`), the **Home** dashboard gives you a quick “Cluster & Stats” overview.  You can also import a simple “API request rates” panel:

1. Dashboards → **Import**
2. Enter **ID 1860** → Select your Prometheus data source → **Import**

---

With that you no longer need MetalLB (Minikube-only), and you’re exposing everything directly on your Elastic IP via NodePorts.








# Gandalf Web Deployment

A simple, modern web server built with **Python** and **Flask**, containerized and deployed in Kubernetes on a single VM.  It serves:

- **`/gandalf`** – a homepage with Gandalf’s picture  
- **`/colombo`** – the current time in Colombo, Sri Lanka  
- **`/metrics`** – Prometheus-style metrics (`gandalf_requests_total`, `colombo_requests_total`)

All traffic is exposed on **port 80** of a single **Elastic IP**, with an NGINX Ingress routing to the three services: web, Prometheus, and Grafana.

---

## Table of Contents

1. [Architecture](#architecture)  
2. [Prerequisites](#prerequisites)  
3. [Getting Started](#getting-started)  
   - [1. Clone & Build](#1-clone--build)  
   - [2. Terraform Provisioning](#2-terraform-provisioning)  
   - [3. User-Data Bootstrap](#3-user-data-bootstrap)  
4. [Kubernetes Deployment](#kubernetes-deployment)  
   - [Services & Ingress](#services--ingress)  
5. [Prometheus & Grafana Usage](#prometheus--grafana-usage)  
   - [Accessing UIs](#accessing-uis)  
   - [Prometheus Queries](#prometheus-queries)  
   - [Grafana Dashboards](#grafana-dashboards)  
   - [Creating Alerts](#creating-alerts)  
6. [Commands Reference](#commands-reference)  
7. [Cleanup](#cleanup)  

---

## Architecture

```

```
    ┌────────────────────────────────────────┐
    │         Elastic IP:80                 │
    │                                        │
    │  ┌──────────┐  ┌─────────────┐        │
    │  │ ingress  │──│ Service →   │        │
    │  │ controller│  └────────────┘        │
    │  │          │        │                │
    │  └──────────┘        ▼                │
    │      │         ┌───────────┐           │
    │      └────────▶│ web:80    │─┐         │
    │                └───────────┘ │         │
    │                              │         │
    │                ┌───────────┐ │         │
    │                │ prometheus│ │         │
    │                │ :9090     │ │         │
    │                └───────────┘ │         │
    │                              │         │
    │                ┌───────────┐ │         │
    │                │ grafana   │─┘         │
    │                │ :3000     │           │
    │                └───────────┘           │
    └────────────────────────────────────────┘
```

````

- **Ingress-NGINX** listens on host port 80  
- Routes `/gandalf`, `/colombo`, `/metrics` → **web**  
- Routes `/prometheus` → **Prometheus** UI + metrics scrape  
- Routes `/grafana` → **Grafana** UI  

---

## Prerequisites

- An AWS (or other cloud) account  
- Terraform ≥ 1.2  
- Docker ≥ 20.10  
- A local machine with `ssh` & `kubectl` installed  
- Helm 3  
- A GitHub repository for the Helm chart & code  

---

## Getting Started

### 1. Clone & Build

```bash
git clone https://github.com/your-org/k8s-web-deployment.git
cd k8s-web-deployment
docker build -t gandalf-web:latest .
````

### 2. Terraform Provisioning

In `terraform/` you have:

* **VPC** + subnets
* **EC2** instance with user-data bootstrap

```bash
cd terraform
terraform init
terraform apply -auto-approve \
  -var "dockerhub_user=<your-dockerhub-username>" \
  -var "my_ip=$(curl -s ifconfig.me)/32"
```

This spins up a VM with an Elastic IP, injects your Docker Hub credentials, and passes the bootstrap script.

### 3. User-Data Bootstrap

On first boot, the EC2 runs `/modules/ec2/minikube.sh` which:

1. Installs Docker, kubectl, Minikube
2. Starts Minikube with the Docker driver
3. Enables `metrics-server` addon
4. Installs MetalLB (if using LoadBalancer) **or** you can skip MetalLB and use Ingress on port 80
5. Clones the Git repo & installs:

   * **Prometheus Operator** (kube-prometheus-stack)
   * **Your Gandalf Helm chart**

---

## Kubernetes Deployment

### Services & Ingress

1. **Modify** each Service to `type: ClusterIP`
2. **Deploy** the NGINX Ingress Controller:

   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm install ingress ingress-nginx/ingress-nginx \
     --namespace ingress-nginx --create-namespace \
     --set controller.hostPort.enabled=true \
     --set controller.hostPort.ports.http=80
   ```
3. **Apply** your application manifests & Ingress:

   ```bash
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service-web.yaml
   kubectl apply -f k8s/service-prometheus.yaml
   kubectl apply -f k8s/service-grafana.yaml
   kubectl apply -f k8s/ingress.yaml
   ```
4. Confirm:

   ```bash
   kubectl get pods,svc,ing -A
   ```

Your application is now live at `http://<Elastic-IP>/gandalf`, etc.

---

## Prometheus & Grafana Usage

### Accessing UIs

* **Prometheus** → `http://<Elastic-IP>/prometheus`
* **Grafana** → `http://<Elastic-IP>/grafana`

  * **Login:** `admin` / `prom-operator`

### Prometheus Queries

| Metric                   | Description         | Example Query                      |
| ------------------------ | ------------------- | ---------------------------------- |
| `gandalf_requests_total` | Total homepage hits | `rate(gandalf_requests_total[1m])` |
| `colombo_requests_total` | Total /colombo hits | `rate(colombo_requests_total[1m])` |

1. In **Prometheus UI** → **Graph** tab
2. Enter a query such as:

   ```promql
   rate(gandalf_requests_total[5m])
   ```
3. Hit **Execute** and view the chart.

### Grafana Dashboards

1. **Add Prometheus** as a data source (should already be auto-configured).
2. **Import** a dashboard:

   * Click **“+” → Import**
   * Enter **ID 1860** (Prometheus 2.0 stats) or any dashboard of your choice.
3. Browse panels showing request rates, CPU/memory, etc.

### Creating Alerts

In Grafana 8+ builtin alerting:

1. Edit any panel (e.g. API request rate).
2. Go to **Alert** tab → **Create Alert**.
3. Define rule:

   * **A:** `sum(rate(colombo_requests_total[1m]))`
   * **WHEN** avg() **OF** A **>** 1
   * **Evaluate every** 1m, **For** 2m
4. Set **Notification channel**, **Save**.

---

## Commands Reference

```bash
# Check cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Ingress
kubectl get ing -n default

# Port-forward (dev)
kubectl port-forward svc/gandalf-web 8080:80

# Reload Helm
helm upgrade --install gandalf ./gandalf-chart \
  --set image.tag=v0.9
```

---

## Cleanup

To destroy everything:

```bash
cd terraform
terraform destroy -auto-approve
```

---

## License

This project is licensed under the MIT License.

```
```
