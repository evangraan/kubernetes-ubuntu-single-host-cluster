# Introduction

Setting up kubernetes can be daunting. This repository provides a quick and easy reference for setting up a development cluster on a single virtualization host.

Helpful ```ops_*``` commands are provided to wrap kubeadm and kubectl commands.

# Requirements

At least one control node:

1. hostname: k8s-control01
2. 4 Gb RAM
3. 2 CPUs
4. Networking such that internet access is available and worker nodes are reachable
5. Ubuntu 20.04 installed on the VM
6. For convenience, make the username on the node the same on each node and the same as your host username

At least one worker node:

1. hostname: k8s-worker01
2. 4 Gb RAM
3. 2 CPUs
4. Networking such that internet access is available and worker nodes and control plane nodes are reachable
5. Ubuntu 20.04 installed on the VM
6. For convenience, make the username on the node the same on each node and the same as your host username

# Setup of host

1. Boot up the control nodes and worker nodes.
2. Determine their IP addresses (either from your DHCP router or by ```ip a l``` on the nodes after they have booted)
3. Place entries in the host OS's hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.155 k8s-cluster
192.168.1.155 k8s-control01
192.168.1.187 k8s-worker01
192.168.1.193 k8s-worker02
```

# Installation of control node

Once Ubuntu 20.04 has been installed, copy the ```install_control.sh``` script onto the node:

From the host:

```
cd kubernetes-ubuntu-single-host-cluster
scp scripts/control/* $USER@k8s-control01:
```

Log into the worker and run the script:

```
ssh $USER@k8s-control01
$ sudo ./install_control.sh
```

Copy the cluster's config to the user's home in ```$HOME/.kube/config```
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Place entries in the node hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.155 k8s-cluster
192.168.1.155 k8s-control01
192.168.1.187 k8s-worker01
192.168.1.193 k8s-worker02
```

Install the calico CNI:
```
./install_calico_cni.sh
```


Initialize the cluster for your network and mask (e.g. ```192.168.1.0/24```):
```
./ops_start_cluster NETWORK/MASK
```

*Important*: take careful note of the TOKEN and HASH that is printed. You will need these in order for workers to join. If you want to add more control nodes as well, also take note of the TOKEN and HASH for control nodes.

# Installation of worker node

Once Ubuntu 20.04 has been installed, copy the ```install_worker.sh``` script onto the node:

From the host:

```
cd kubernetes-ubuntu-single-host-cluster
scp scripts/worker/* $USER@k8s-worker01:
```

Log into the worker and run the script:

```
ssh $USER@k8s-worker01
$ sudo ./install_worker.sh
```

Copy the cluster's config from the control node (located in ```$HOME/.kube/config``` on the control node) and place it on the worked node in ```$HOME/.kube```

```
mkdir -p $HOME/.kube
# Copy control node config to $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Place entries in the node hosts file that resolves these IPs:

```
$ sudo vi /etc/hosts
192.168.1.155 k8s-cluster
192.168.1.155 k8s-control01
192.168.1.187 k8s-worker01
192.168.1.193 k8s-worker02
```

Install the calico CNI:
```
./install_calico_cni.sh
```

Join the cluster using the cluster token and hash:

```
./ops_join_cluster TOKEN HASH
```

# Static network routing

If you have trouble connecting to your control or worker nodes from a development device on the same network, or your workers do not become Ready and
report Kubelet stopped posting node status, this may be due to your network
characteristics. The cluster network might not be able to properly route packets between the node. This might be due to your router and/or your virtualization host networking. This problem can be solved by network layer
routing (static IP routing.)

For each worker, ensure that it has a static ip route to the controller.
For the controller, ensure that it has a static IP to each worker.
For each node, ensure that it has a static route to the development device.

Determine the interface for your network and then do:
```
sudo ip route add IP dev INTERFACE
```

Example:
```
sudo ip route add 192.168.1.239 dev enp0s3
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
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
```

View the service in the services list and note the CLUSTER-IP:
```
./ops_get_services
```

Test that the app is running by sending it some data and seeing the echo:
```
curl -X POST -d 'test' CLUSTER-IP:8080
```

# External access to the app
Kubernetes provides a number of methods to allow external access to the cluster to consume services.

For simple testing, one can also simply do SSH tunneling to the cluster IP:

```
ssh -L 8080:CLUSTER-IP:8080 $USER@k8s-control01
```

Point a browser on the development device to http://localhost:8080 to consume the service (or use curl)

```
curl -X POST -d 'test' localhost:8080
```

MetalLB : TBD
Other method examples: TBD

# Scaling

TBD

# Storage

ZFS + DRBD: TBD

# Issues

See [DEBUGGING](DEBUGGING.md) to find solutions to common problems