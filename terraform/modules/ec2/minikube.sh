#!/usr/bin/env bash
set -euxo pipefail

OS_USER="ubuntu"

apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
     -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io \
                   docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker "$OS_USER"

echo "Installing kubectl…"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client -o yaml | grep gitVersion

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
dpkg -i minikube_latest_amd64.deb
rm minikube_latest_amd64.deb

# start cluster exactly the way that works for you
su - "$OS_USER" -c 'minikube start --driver=docker --wait=true && minikube addons enable metrics-server'

# ——— Helm + repos ———
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update



echo "User-data bootstrap complete – cluster, monitoring and Gandalf are up."
