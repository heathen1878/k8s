# Variables
KUBECONFIG_FILE=~/.kube/config
VAGRANT_CONFIG_DIR=shared
JOIN_SCRIPT_PATH=$(VAGRANT_CONFIG_DIR)/join.sh

# Rebuild entire cluster
rebuild:
	@echo "🔁 Destroying and rebuilding Kubernetes cluster..."
	@vagrant destroy -f
	@vagrant up
	@echo "Cluster rebuilt successfully."

# Copy kubeconfig from master to host machine
kubeconfig:
	@echo "📥 Copying kubeconfig from master node..."
	vagrant ssh master -c "sudo cat /etc/kubernetes/admin.conf" > $(KUBECONFIG_FILE)
	@sed -i.bak 's/https:\/\/.*:6443/https:\/\/127.0.0.1:6443/' $(KUBECONFIG_FILE)
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "✅ KUBECONFIG updated at $(KUBECONFIG_FILE)"

# Show cluster status
status:
	kubectl get nodes -o wide