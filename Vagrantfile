Vagrant.configure("2") do |config|
	config.vm.box = "bento/centos-8"
	# bento/centos-7.3 to fix shared_folders issue

	#config.ssh.private_key_path = ["~/.ssh/id_rsa", "~/.vagrant.d/insecure_private_key"]
	### config.vm.box_check_update = false
	### config.vm.network "forwarded_port", guest: 80, host: 8080
	### config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
	#config.vm.network "public_network"

	#config.vm.synced_folder ".", "/v-data", type: "rsync", rsync__exclude: ".git/"
	#     ,:user=>nginx, :owner=>nginx
	
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false  
    end
	config.vm.network "private_network", ip: "10.0.0.10"

	config.vm.provision "shell", path: "provision-centos.sh"
end