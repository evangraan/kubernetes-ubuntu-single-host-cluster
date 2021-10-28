#!/bin/bash
echo "Updating apt"
sudo apt -y update
echo "Upgrading system"
sudo apt -y upgrade
echo "Install API transport"
sudo apt -y install curl apt-transport-https
echo "Registering kubernetes packages"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "Updating apt"
sudo apt -y update
echo "Install kubernetes"
sudo apt -y install vim git curl wget kubelet kubeadm kubectl
echo "Prevent automatic updates and mark kubernetes as manually installed"
sudo apt-mark hold kubelet kubeadm kubectl
echo "Disable swap"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
echo "Enable kernel modules"
sudo modprobe overlay
sudo modprobe br_netfilter
echo "Configure network bridging"
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
echo "Install docker"
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
sudo mkdir -p /etc/systemd/system/docker.service.d
echo "Configure docker daemon and start docker"
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
