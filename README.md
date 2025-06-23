# Kubernetes

## Versions

### v1.0.0

This repo contains the code to build a K8s cluster using Vagrant.

The cluster comprises of....
 - 3 nodes; 1 node runs all control plane components and 2 worker nodes
 - CNI uses flannel
 - Kube VIP load balancer and kube VIP cloud controller
 - NGINX Ingress controller

### v1.1.0

Added Federated Identity functionality. 

This requires the steps documented [here](https://azure.github.io/azure-workload-identity/docs/introduction.html) are followed...

Steps:

```shell
make help
```

![](assets/help.png)

Your vagrant_config.yaml will need to look like below.

```yaml
nodes:
  k8s-master:
    ip: ip_address
    role: master
  k8s-worker1:
    ip: ip_address
    role: worker
  k8s-worker2:
    ip: ip_address
    role: worker
```

```shell
# This will build a fresh cluster and copy the kube configuration locally.
make build
```

![](assets/build1.png)

___
![](assets/build2.png)

```shell
# To SSH into the nodes
make ssh-[ master | worker1 | worker2 ]
```

![](assets/ssh.png)

```shell
# Destroys the cluster and removes the local kube configuration.
make clean
```

![](assets/clean.png)