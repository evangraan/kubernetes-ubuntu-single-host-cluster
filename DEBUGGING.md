# Debugging nodes

On the node:
```
sudo systemctl restart kubelet
journalctl -u kubelet
```

The journal entries might point to the issue.

# Worker node status Unknown

Symptoms: kubectl describe nodes reports 'Kubelet stopped posting node status'

Solution: Add static network routing

If you have trouble connecting to your control or worker nodes from a development device on the same network, or your workers do not become Ready and
report Kubelet stopped posting node status, this may be due to your network
characteristics / issues.

First, make sure the CIDR you initialized the cluster with is different from your host network.

If it is, the cluster network might not be able to properly route packets between the node. This might be due to your router and/or your virtualization host networking. This problem can be solved by network layer
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