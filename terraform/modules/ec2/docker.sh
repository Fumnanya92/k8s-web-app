#!/usr/bin/env bash
set -euxo pipefail

###############################################################################
# 0.  Variables (inject via Terraform -var or via Metadata/Substitution)
###############################################################################
TAG="${IMAGE_TAG}"             # e.g. "v0.8"
DH_USER="${DOCKERHUB_USERNAME}"
WEB_PORT=80
PROM_PORT=9090

###############################################################################
# 1.  Install Docker
###############################################################################
apt-get update -y
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Add Docker’s official GPG key & repo
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

###############################################################################
# 2.  Run Gandalf Web on port 80
###############################################################################
# Pull the tagged image, fallback to :latest if the tag isn’t on Docker Hub
docker pull docker.io/${DH_USER}/gandalf-web:${TAG} \
   || docker pull docker.io/${DH_USER}/gandalf-web:latest

# Start container
docker run -d \
  --name gandalf-web \
  --restart unless-stopped \
  -p ${WEB_PORT}:80 \
  docker.io/${DH_USER}/gandalf-web:${TAG}

###############################################################################
# 3.  Run Prometheus on port 9090
###############################################################################
mkdir -p /opt/prometheus
cat >/opt/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'gandalf-web'
    static_configs:
      - targets: ['localhost:${WEB_PORT}']
EOF

docker pull prom/prometheus:latest
docker run -d \
  --name prometheus \
  --restart unless-stopped \
  -p ${PROM_PORT}:9090 \
  -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest

###############################################################################
# 4.  Done
###############################################################################
echo "🎉 Services started!"
echo "→ Gandalf Web: http://$(curl -s ifconfig.me)/gandalf"
echo "→ Colombo Time: http://$(curl -s ifconfig.me)/colombo"
echo "→ Prometheus : http://$(curl -s ifconfig.me):${PROM_PORT}"
