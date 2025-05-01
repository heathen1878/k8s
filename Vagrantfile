
Vagrant.configure("2") do |config|
    nodes = {
        "k8s-master" => "192.168.56.10",
        "k8s-worker1" => "192.168.56.20",
        "k8s-worker2" => "192.168.56.21"
    }

    config.vm.box = "ubuntu/jammy64"

    nodes.each do |name, ip|
        config.vm.define name do |node|
            node.vm.hostname = name
            node.vm.network "private_network", ip: ip
            node.vm.provider "virtualbox" do |vb|
                vb.name = name
                vb.memory = 2048
                vb.cpus = 2
            end

            # Expose Kubernetes API server port to host from master node
            if name == "master"
                node.vm.network "forwarded_port", guest: 6443, host: 6443, auto_correct: true
            end

            node.vm.provision "shell", path: "scripts/provisioning.sh"
        end
    end
end