# -*- mode: ruby -*-
# vi: set ft=ruby :
#

begin
  vbox_version = `VBoxManage --version`
rescue
  vbox_version = 0
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  box = ENV['VAGRANT_BOX'] || "nixos/nixos-16.09-x86_64"

  machines = [
    { 'name' => 'vagrant-mesos-zk-01',
      'ip' =>  '192.168.56.201' 
    },
    { 'name' => 'vagrant-mesos-zk-02',
      'ip' =>  '192.168.56.202' 
    },
    { 'name' => 'vagrant-mesos-zk-03',
      'ip' =>  '192.168.56.203' 
    },
    { 'name' => 'vagrant-mesos-slave',
      'ip' =>  '192.168.56.204' 
    }
  ]

  machines.each do |item|
    config.vm.define item['name'] do |machine|

      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
      end

      machine.vm.box = box
      machine.vm.hostname = item['name']
      machine.vm.network "private_network", ip: item['ip']
      machine.ssh.insert_key = false

      machine.vm.provider "virtualbox" do |vb|
        vb.memory = "2048" # to compile mesos we need > 2GB of RAM
        # https://github.com/hashicorp/otto/issues/423#issuecomment-186076403
        vb.linked_clone = true if Vagrant::VERSION =~ /^1.9/ 
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        if vbox_version.to_f >= 5.0 and  Vagrant::Util::Platform.linux?
          vb.customize ['modifyvm', :id, '--paravirtprovider', 'kvm']
        end
        # https://www.virtualbox.org/manual/ch05.html#iocaching
        # disable hostio-cache to save memory
        vb.customize [
          "storagectl", :id, 
          "--name", "IDE Controller",
          "--hostiocache", "off"
        ]
      end

      machine.vm.synced_folder "#{item['name']}", "/etc/nixos/"
      machine.vm.synced_folder "common", "/etc/nixos/common"
      machine.vm.synced_folder "config", "/etc/nixos/config"

      machine.vm.provision "shell", path: "update.sh"
    end
  end
end
