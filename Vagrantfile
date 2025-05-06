require 'yaml'

config_data = YAML.load_file('vagrant/vagrant_config.yaml')

Vagrant.configure("2") do |config|

    config.vm.box = "ubuntu/jammy64"

    bridge_iface = ENV["BRIDGE_IFACE"]
    raise "❌ BRIDGE_IFACE is not set. Use: BRIDGE_IFACE=wlp4s0 make up" unless bridge_iface && !bridge_iface.empty?

    config_data['nodes'].each do |name, details|
        ip = details['ip']
        raise "❌ IP address for #{name} is not set. Please check vagrant_config.yaml" unless ip && !ip.empty?
        role = details['role']
        raise "❌ Role for #{name} is not set. Please check vagrant_config.yaml" unless role && !role.empty?
        raise "❌ Role #{role} is not supported. Please check vagrant_config.yaml" unless ['master', 'worker'].include?(role)

        config.vm.define name do |node|
            node.vm.hostname = name
            node.vm.boot_timeout = 180

            # Add bridged adapter; this will be used for all communication after the initial conifguration.
            node.vm.network "public_network", ip: nil, bridge: bridge_iface, auto_config: false

            node.vm.provider "virtualbox" do |vb|
                vb.name = name
                vb.memory = details['memory'] || 2048
                vb.cpus = details['cpus'] || 2
                vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
                vb.customize ["modifyvm", :id, "--macaddress2", "auto"]
            end

            node.vm.synced_folder "shared", "/vagrant/shared", type: "virtualbox"
            if role == master
                node.vm.synced_folder "manifests", "/vagrant/manifests", type: "virtualbox"
                node.provision "shell", path: "scripts/master.sh", env: { "STATIC_IP" => ip}
            elsif role == worker
                node.vm.provision "shell", path: "scripts/worker.sh", env: { "STATIC_IP" => ip}
            end
        end
    end
end