# Variables
KUBECONFIG_FILE=~/.kube/config
VAGRANT_CONFIG_DIR=shared
JOIN_SCRIPT_PATH=$(VAGRANT_CONFIG_DIR)/join.sh
BRIDGE_IFACE ?= enp1s0f0
export BRIDGE_IFACE

# Show help with descriptions
help:
	@echo ""
	@echo "📦 Available make targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""

build: ## Build Kubernetes cluster
	@echo "🚀 Building Kubernetes cluster..."
	@vagrant up
	@echo "Cluster built successfully."
	@sleep 30
	@echo "📥 Copying kubeconfig to host machine..."
	@vagrant ssh k8s-master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"
	@echo "Kubernetes nodes"
	@kubectl get nodes -o wide
	@sleep 20
	@echo "Installing mutating Admission Webhook for Federated Identity"
	@read -p "Paste or type your Azure Tenant GUID: " TENANT_ID; \
		helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts; \
		helm repo update  > /dev/null 2>&1; \
		helm upgrade --install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
		--namespace azure-workload-identity-system \
		--create-namespace \
		--set azureTenantID=$$TENANT_ID
	@echo "Installing and configuring Kube VIP..."
	@kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
	@kubectl apply -f manifests/kubevip-config.yml
	@kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml
	@echo "Installing NGINX as an Ingress Controller using Helm"
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	@helm repo update  > /dev/null 2>&1
	@helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		-f helm/nginx/values.yaml > /dev/null 2>&1
	@echo "NGINX deployed..."

rebuild: ## Rebuild entire cluster
	@echo "🔁 Destroying and rebuilding Kubernetes cluster..."
	@make clean
	@make build
	@echo "Cluster rebuilt successfully."

ssh-master: ## SSH into master node
	@echo "🔑 SSH into master node..."
	vagrant ssh k8s-master

ssh-worker1: ## SSH into worker node 1
	@echo "🔑 SSH into worker node..."
	vagrant ssh k8s-worker1

ssh-worker2: ## SSH into worker node 2
	@echo "🔑 SSH into worker node..."
	vagrant ssh k8s-worker2
	
clean: ## Clean up everything
	@echo "🧹 Cleaning up..."
	vagrant destroy -f
	rm -f $(KUBECONFIG_FILE)
	rm -f $(JOIN_SCRIPT_PATH)

.PHONY: help build rebuild ssh-master ssh-worker1 ssh-worker2 clean
