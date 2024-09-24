#!/bin/bash

DOCKER_VERSION="5:20.10.21~3-0~ubuntu-jammy"
KUBERNETES_VERSION="1.29.0-00"
hostname -I | awk '{print $NF}' > /tmp/ip.txt

# turn off swap - for the Kubelet
swapoff -a 
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# install Docker
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y \
    docker-ce=$DOCKER_VERSION \
    docker-ce-cli=$DOCKER_VERSION \
    containerd.io

# install cri-dockerd
apt-get install -y golang-go

git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
git checkout v0.3.0

mkdir bin
go build -o bin/cri-dockerd

cp bin/cri-dockerd /usr/local/bin/
cp packaging/systemd/* /etc/systemd/system/
sed -i 's!/usr/bin/cri-dockerd!/usr/local/bin/cri-dockerd!' /etc/systemd/system/cri-docker.service

systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket

# install Kubeadm etc.
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y \
    kubelet=$KUBERNETES_VERSION \
    kubeadm=$KUBERNETES_VERSION \
    kubectl=$KUBERNETES_VERSION

# Configure kubelet to use cri-dockerd
cat <<EOF | tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///var/run/cri-dockerd.sock
EOF

systemctl daemon-reload
systemctl restart kubelet

# set iptables for Flannel
sysctl net.bridge.bridge-nf-call-iptables=1
