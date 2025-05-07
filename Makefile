# Variables
KUBECONFIG_FILE=~/.kube/config
VAGRANT_CONFIG_DIR=shared
JOIN_SCRIPT_PATH=$(VAGRANT_CONFIG_DIR)/join.sh
BRIDGE_IFACE ?= wlp4s0
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
	@echo "📥 Copying kubeconfig to host machine..."
	@vagrant ssh k8s-master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"
	@echo "Kubernetes nodes"
	kubectl get nodes -o wide

rebuild: ## Rebuild entire cluster
	@echo "🔁 Destroying and rebuilding Kubernetes cluster..."
	@vagrant destroy -f
	@vagrant up
	@echo "Cluster rebuilt successfully."

start: ## Start Kubernetes cluster
	@echo "🚀 Starting Kubernetes cluster..."
	@vagrant up
	@echo "Cluster started successfully."

stop: ## Stop Kubernetes cluster
	@echo "⏸️ Stopping Kubernetes cluster..."
	@vagrant halt
	@echo "Cluster stopped successfully."

vagrant-status: ## Get Vagrant status
	@echo "🔍 Get Vagrant status..."
	@vagrant status

kubeconfig: ## Copy kubeconfig from master to host machine
	@echo "📥 Copying kubeconfig from master node..."
	vagrant ssh k8s-master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"

ssh-master: ## SSH into master node
	@echo "🔑 SSH into master node..."
	vagrant ssh k8s-master

ssh-worker1: ## SSH into worker node 1
	@echo "🔑 SSH into worker node..."
	vagrant ssh k8s-worker1

ssh-worker2: ## SSH into worker node 2
	@echo "🔑 SSH into worker node..."
	vagrant ssh k8s-worker2
	
status: ## Show cluster status
	kubectl get nodes -o wide

clean: ## Clean up everything
	@echo "🧹 Cleaning up..."
	vagrant destroy -f
	rm -f $(KUBECONFIG_FILE)
	rm -f $(JOIN_SCRIPT_PATH)


.PHONY: help build rebuild vagrant-status start stop kubeconfig ssh-master ssh-worker1 ssh-worker2 status clean