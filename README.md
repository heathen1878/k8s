# Kubernetes

This repo contains the code to build a K8s cluster using Vagrant.

Steps:

```shell
#Initialise K8s
vagrant ssh master

sudo kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=10.244.0.0/16
```

```shell
# Grab the admin.conf on the master node
mkdir -p $HOME/.kube

sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# and install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

```shell
# On the master node
kubeadm token create --print-join-command

# On the worker node
sudo kubeadm join 192.168.56.10:6443 \
    --token ***** \
    --discovery-token-ca-cert-hash sha256:******
```

```shell
# Grab k8s config file
vagrant ssh k8s-master

# grab config
cat /etc/kubernetes/admin.conf 

# copy and paste into 
~/.kube/config
```