# Debugging nodes

On the node:
```
sudo systemctl restart kubelet
journalctl -u kubelet
```

The journal entries might point to the issue.

# Worker node status Unknown
Symptoms: kubectl describe nodes reports 'Kubelet stopped posting node status'
Solution: Add static routes as described in README.md