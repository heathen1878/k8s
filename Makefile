# Variables
KUBECONFIG_FILE=~/.kube/config
VAGRANT_CONFIG_DIR=shared
JOIN_SCRIPT_PATH=$(VAGRANT_CONFIG_DIR)/join.sh

# Show help with descriptions
help:
	@echo ""
	@echo "📦 Available make targets:"
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""

build:
	@echo "🚀 Building Kubernetes cluster..."
	@vagrant up
	@echo "Cluster built successfully."
	@echo "🔑 Copying kubeconfig to host machine..."
	@vagrant ssh master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"

rebuild: ## Rebuild entire cluster
	@echo "🔁 Destroying and rebuilding Kubernetes cluster..."
	@vagrant destroy -f
	@vagrant up
	@echo "Cluster rebuilt successfully."

kubeconfig: ## Copy kubeconfig from master to host machine
	@echo "📥 Copying kubeconfig from master node..."
	vagrant ssh k8s-master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"

# Show cluster status
status:
	kubectl get nodes -o wide

# Clean everything
clean:
	@echo "🧹 Cleaning up..."
	vagrant destroy -f
	rm -f $(KUBECONFIG_FILE)
	rm -f $(JOIN_SCRIPT_PATH)


.PHONY: build rebuild kubeconfig status