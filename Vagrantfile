# -*- mode: ruby -*-
# vi: set ft=ruby :

ANSIBLE_NAME = "RaibeartSelinux"
SERVER_IP = "192.168.10.11"

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
    config.vm.define "server" do |server|
    server.vm.hostname = "server"
    server.vm.network "private_network", ip: SERVER_IP
    server.vm.provision "ansible" do |ansible|
      ansible.playbook = "params/site.yml"	
    end
  end
end
