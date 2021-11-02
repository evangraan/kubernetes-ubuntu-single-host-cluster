# Introduction

This repository provides a reference for setting up a development cluster on a single virtualization host.

Helpful ```ops_*``` commands are provided to wrap kubeadm and kubectl commands. These are not an attempt at something like kops (https://github.com/kubernetes/kops) at all. They are simple wrappers for common provisioning use cases only.

This repo was tested with VirtualBox on maxOS Catalina and Windows 10

- [Introduction](#introduction)
- [Automated Provisioning](#automated-provisioning)
- [Requirements](#requirements)
- [Host setup](#host-setup)
- [Controllers](#controllers)
- [Workers](#workers)
- [Helm](#helm)
- [App deployment](#app-deployment)
- [External access](#external-access)
  - [Nodeport](#nodeport)
  - [Load balancer](#load-balancer)
  - [SSH tunnel](#ssh-tunnel)
- [Storage](#storage)
- [Using storage pools in kubernetes](#using-storage-pools-in-kubernetes)
- [Issues](#issues)

# Automated Provisioning

The sections below detail step-by-step manual setup of the cluster. If you would like to set it up automatically, tweak the Vagrantfile in this repository to your needs. This Vagrantfile works with VirtualBox. Install vagrant on your host.

Edit ```Vagrantfile.cluster``` and set the static IP addresses you would like to use in the ```/etc/hosts``` section. Also set the internal kubernetes network CIDR.

Copy the Vagrantfile you want to run (```Vagrantfile.cluster``` or ```Vagrantfile.storage```) to Vagrantfile and then:

```
vagrant up
```

To clean up (destroy) the cluster VMs and release resources:

```
vagrant destroy
```

To SSH into systems:

```
vagrant ssh k8s-control01
vagrant ssh k8s-worker01
vagrant ssh k8s-worker02
```

WARNING: this repo publishes a test SSH key pair. Generate your own secure key pair and replace id_rsa and id_rsa.pub before creating the cluster.

To additionally add a storage cluster, you can use the vagrant configuration provided in the [storage](./README.md#Storage) section of this README.

# Requirements

At least one control node:

1. hostname: k8s-control01
2. 4 Gb RAM
3. 2 CPUs
4. 30+ Gb disk
5. Networking such that internet access is available and worker nodes are reachable
6. Ubuntu 20.04 installed on the VM
7. For convenience, make the username on the node the same on each node and the same as your host username

At least one worker node:

1. hostname: k8s-worker01
2. 4 Gb RAM
3. 2 CPUs
4. 30+ Gb disk
5. Networking such that internet access is available and worker nodes and control plane nodes are reachable
6. Ubuntu 20.04 installed on the VM
7. For convenience, make the username on the node the same on each node and the same as your host username

# Host setup

1. Boot up the control nodes and worker nodes.
2. Determine their IP addresses (either from your DHCP router or by ```ip a l``` on the nodes after they have booted)
3. Place entries in the host OS's hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.109 k8s-cluster
192.168.1.109 k8s-control01
192.168.1.147 k8s-worker01
192.168.1.98 k8s-worker02
```

# Controllers

Once Ubuntu 20.04 has been installed, copy ```scripts/control/*``` script onto the node:

From the host:

```
cd kubernetes-ubuntu-single-host-cluster
scp scripts/control/* $USER@k8s-control01:
ssh $USER@k8s-control01 "chmod +x install* ops*"
```

Log into the worker and run the script:

```
ssh $USER@k8s-control01
$ sudo ./install_control.sh
```

Place entries in the node hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.109 k8s-cluster
192.168.1.109 k8s-control01
192.168.1.147 k8s-worker01
192.168.1.98 k8s-worker02
```

Initialize the cluster for your network and mask (e.g. ```192.168.2.0/24```)
Note: make sure the CIDR differs from the host's network.
```
./ops_start_cluster NETWORK/MASK
```

*Important*: take careful note of the TOKEN and HASH that is printed. You will need these in order for workers to join. If you want to add more control nodes as well, also take note of the TOKEN and HASH for control nodes.

Install the calico CNI:
```
./install_calico_cni.sh
```

# Workers

Once Ubuntu 20.04 has been installed, copy ```scripts/worker/*``` script onto the node:

From the host:

```
cd kubernetes-ubuntu-single-host-cluster
scp scripts/worker/* $USER@k8s-worker01:
ssh $USER@k8s-worker01 "chmod +x install* ops*"
```

Log into the worker and run the script:

```
ssh $USER@k8s-worker01
$ sudo ./install_worker.sh
```

Copy the cluster's config from the control node (located in ```$HOME/.kube/config``` on the control node) and place it on the worked node in ```$HOME/.kube```

```
mkdir -p $HOME/.kube
scp $USER@k8s-control01:.kube/config $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Place entries in the node hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.109 k8s-cluster
192.168.1.109 k8s-control01
192.168.1.147 k8s-worker01
192.168.1.98 k8s-worker02
```

Install the calico CNI:
```
./install_calico_cni.sh
```

Join the cluster using the cluster token and hash:

```
./ops_join_cluster TOKEN HASH
```

# Helm
On the control node, install helm:

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

# App deployment

To deploy an example echo service to test that deployment works, on a control node:

```
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
```

You can see details about the pod:

```
./ops_get_pods
```

You can see details about the deployment:

```
./ops_get_deployment
```

Expose the app as a service so that you can access it:
```
kubectl expose deployment hello-node --type=NodePort --name=hello-node-service --port=8080
```

View the service in the services list and note the CLUSTER-IP:
```
./ops_get_services
```

Test that the app is running by sending it some data and seeing the echo:
```
curl -X POST -d 'test' CLUSTER-IP:8080
```

# External access
Kubernetes provides a number of methods to allow external access to the cluster to consume services.

## Nodeport

Note: if your deployment specified type NodePort, there is no need to also expose the service again.
```
kubectl expose service hello-node-service --type=NodePort --name=hello-node-service-external
```

In both cases, if you do:

```
kubectl get service
```

on the *worker* nodes after exposing with type NodePort, the output should include in the PORT(s) columns a value like this:
```
8080:32750(TCP)
```

You can then access the service / deployment on that worker node directly:

```
curl -vvv -X POST -d 'tester' http://k8s-worker-01:32750
```

## Load balancer
Use MetalLB as a load balancer:

```
vi metallb.yaml

  address-pools:
   - name: default
     protocol: layer2
     addresses:
     - LAN-CIDR/MASK-FOR-RESERVED-IP-POOL
     # e.g. 192.168.1.0/26 (.0 - .63 reserved for MetalLB)

helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -f metallb.yaml
```

Then expose services so:
```
kubectl expose deployment hello-node --port=8765 --target-port=8080 --name=hello-node-service --type=LoadBalancer
```

Check the ports and IPs to which the service have been mapped:
```
$ kubectl get service
NAME               TYPE         CLUSTER-IP    EXTERNAL-IP PORT(S)        AGE
hello-node-service LoadBalancer 10.108.87.253 192.168.1.1 8765:31719/TCP 2s
kubernetes         ClusterIP    10.96.0.1     <none>      443/TCP        4h56m
```

Test service access using the external IP and port listed:
```
curl -vvv -X POST -d 'tester' http://192.168.1.1:8765
```

## SSH tunnel
For simple testing, one can also simply do SSH tunneling to the cluster IP:

```
ssh -L 8080:CLUSTER-IP:8080 $USER@k8s-control01
```

Point a browser on the development device to http://localhost:8080 to consume the service (or use curl)

```
curl -X POST -d 'test' localhost:8080
```


# Storage

If storage is desired, a separate vagrant configuration has been provided for convenience:

Making sure you use Vagrantfile.storage, do a vagrant up

Once the VMs are available, power them off and add an additional storage disk to each (at least 2Gb).

Start the VMs up all again and on each do:
```
	sudo pvcreate /dev/sdc # Replace sdc with your storage disk's device index
	sudo vgcreate vg /dev/sdc
	sudo lvcreate -l 100%FREE  --thinpool vg/lvmthinpool
```

Ensure all nodes are configured and online:

```
linstore node list
```

Then on the control node:
```
linstor storage-pool create lvmthin linstor-master1 linstor-pool vg/lvmthinpool
linstor storage-pool create lvmthin linstor-master2 linstor-pool vg/lvmthinpool
linstor storage-pool create lvmthin linstor-master3 linstor-pool vg/lvmthinpool
```

Ensure the storage pool is configured correctly and available:

```
linstor storage-pool list
```

# Using storage pools in kubernetes

On k8s-control01:

```
TAG=v0.7.4
CONTROLLER_IP=192.168.1.20

curl https://raw.githubusercontent.com/LINBIT/linstor-csi/$TAG/examples/k8s/deploy/linstor-csi-1.14.yaml | sed "s/linstor-controller.example.com/$CONTROLLER_IP/g" | kubectl apply -f -

watch kubectl -n kube-system get all
```

Create a storage class:

```
REPLICAS=3

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: linstor
provisioner: linstor.csi.linbit.com
parameters:
  autoPlace: "$REPLICAS"
  storagePool: "linstor-pool"
EOF 
```

Create a PVC test the storage cluster and its use from the kubernetes cluster:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  storageClassName: linstor
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

kubectl get pvc
```

# Issues

See [DEBUGGING](DEBUGGING.md) to find solutions to common problems