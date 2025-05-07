#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Static IP from Vagrant environment
STATIC_IP="${STATIC_IP:-192.168.188.10}"

# Detect current default interface
DEFAULT_IFACE=$(ip route | awk '/^default/ {print $5}' | head -n 1)

# Ubuntu typically uses 'netplan' for network config
# Detect the bridged interface (usually the second one after NAT)
BRIDGED_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | tail -n 1)

echo "📡 Configuring static IP $STATIC_IP on interface $BRIDGED_IFACE"

# Configure netplan manually
cat <<EOF | sudo tee /etc/netplan/99-vagrant-bridged.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $BRIDGED_IFACE:
      addresses:
        - $STATIC_IP/24
      nameservers:
        addresses: [8.8.8.8]
      routes:
        - to: default
          via: 192.168.188.1
EOF

# Set permissions for netplan config
sudo chmod 600 /etc/netplan/99-vagrant-bridged.yaml

# Apply network config
sudo netplan apply 2>&1 | grep -v 'Cannot call Open vSwitch' || true

# Only remove default route if it’s via the NAT interface (not the bridged one)
if [[ "$DEFAULT_IFACE" != "$BRIDGED_IFACE" && -n "$DEFAULT_IFACE" ]]; then
  echo "⚠️ Removing default route via $DEFAULT_IFACE"
  ip route del default dev "$DEFAULT_IFACE" || true
fi

# Ensure correct hostname
hostnamectl set-hostname "$(hostname)"
echo "127.0.0.1 $(hostname)" >> /etc/hosts

echo "✅ Master node static IP and hostname configured: $STATIC_IP"

# Variables
K8S_VERSION="v1.30"  # Change to v1.29, v1.28 etc. as needed
K8S_KEYRING=/etc/apt/keyrings/kubernetes-apt-keyring.gpg
PAUSE_IMAGE="registry.k8s.io/pause:3.9"
CONTAINERD_CONFIG=/etc/containerd/config.toml

# 1. Disable swap (Kubernetes requirement)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Update and install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. Install Containerd
apt-get install -y containerd

if [ ! -f "$CONTAINERD_CONFIG" ]; then
  mkdir -p /etc/containerd
  containerd config default > "$CONTAINERD_CONFIG"
fi

# Update pause image and enable systemd cgroups
sed -i "s|sandbox_image = \".*\"|sandbox_image = \"${PAUSE_IMAGE}\"|" "$CONTAINERD_CONFIG"
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$CONTAINERD_CONFIG"


systemctl restart containerd
systemctl enable containerd

# 4. Add Kubernetes GPG key
# === INSTALL KUBERNETES GPG KEY (idempotent) ===
if [ ! -f "$K8S_KEYRING" ]; then
  echo "🔑 Adding Kubernetes APT GPG key..."
  mkdir -p /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" -o /tmp/k8s-release.key
  gpg --dearmor < /tmp/k8s-release.key > "$K8S_KEYRING"
  rm /tmp/k8s-release.key
else
  echo "✅ Kubernetes APT key already present. Skipping."
fi

# 5. Add Kubernetes repo (with allow-insecure workaround)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# 6. Install Kubernetes tools
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 7. Enable bridged traffic forwarding
# Load kernel module
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Apply sysctl settings
sysctl --system

echo "✅ Kubernetes ${K8S_VERSION} setup complete."

# Variables
JOIN_FILE="/vagrant/shared/join.sh"

# 8. Initialize Kubernetes master node
echo "🚀 Initializing Kubernetes master node..."
kubeadm init --config="/vagrant/manifests/kubeadm-config.yml"

# 9. Set up kubeconfig for root user
echo "🔐 Setting up kubeconfig for vagrant user..."
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# 10. Install Flannel CNI
echo "🌐 Installing Flannel CNI..."
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

# 11. Generate join command for worker nodes
echo "🔗 Generating join command for workers..."
kubeadm token create --print-join-command > "$JOIN_FILE"
chmod +x "$JOIN_FILE"

echo "✅ Master initialization complete. Join command written to $JOIN_FILE"