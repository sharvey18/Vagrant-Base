# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

CONFIG = File.join(File.dirname(__FILE__), "vagrant-files", "config.rb")

# defaults for config settings
$forwarded_ports = {
    80 => 8080,
    443 => 8443,
    3306 => 3336
}
$use_nfs = true

if File.exist?(CONFIG)
    require CONFIG
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    # define base box
    config.vm.box = "debian-7-clean-20150721"
    config.vm.box_url = "http://vagrant.vuria.com/debian-7-clean-20150721.box"

    # set up forwarded ports
    $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host
    end

    # set up networking
    config.vm.host_name = "vagrant"
    config.vm.network :private_network, type: "dhcp"

    # set up synced folder
    if $use_nfs
        config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "actimeo=1"]
    end

    # give vm 1024MB of memory
    config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

    # run provisioning script
    config.vm.provision :shell, :path => "vagrant-files/provision.sh"
end
