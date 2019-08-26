# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false

  servers = [
      {
          :hostname => "k8s-master",
          :ip => "192.168.100.10",
          :box => "ubuntu/bionic64",
          :ram => 1024,
          :cpu => 1,
          :bootstrap_script => "scripts/bootstrap-master.sh"
      },
      {
          :hostname => "k8s-node",
          :ip => "192.168.100.11",
          :box => "ubuntu/bionic64",
          :ram => 1024,
          :cpu => 1,
          :bootstrap_script => "scripts/bootstrap-node.sh"
      },{
          :hostname => "k8s-node2",
          :ip => "192.168.100.12",
          :box => "ubuntu/bionic64",
          :ram => 1024,
          :cpu => 1,
          :bootstrap_script => "scripts/bootstrap-node.sh"
      }
  ]

  servers.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.network "private_network", ip: machine[:ip]
      node.vm.provider "virtualbox" do |vb|
        vb.name = machine[:hostname]
        vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
      end
      node.vm.provision :shell, path: machine[:bootstrap_script]
    end
  end
end

