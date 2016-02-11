# -*- mode: ruby -*-
# vi: set ft=ruby :


require "./catapult/catapult.rb"


Vagrant.configure("2") do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  # dev => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-redhat" do |config|
    config.vm.box = "puppetlabs/centos-7.0-64-nocm"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["redhat"]["ip"]
    config.vm.network "forwarded_port", guest: 80, host: Catapult::Command.configuration["environments"]["dev"]["servers"]["redhat"]["port_80"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    # configure hosts file on both the host and guest
    config.vm.provision :hostmanager
    config.hostmanager.aliases = Catapult::Command.dev_redhat_hosts
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/catapult", type: "nfs"
    # sync the repositories folder for local access from the host
    config.vm.synced_folder "repositories", "/var/www/repositories", type: "nfs"
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","apache","#{Catapult::Command.configuration_user["settings"]["software_validation"]}"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-redhat-mysql" do |config|
    config.vm.box = "puppetlabs/centos-7.0-64-nocm"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["redhat_mysql"]["ip"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    # configure hosts file on both the host and guest
    config.vm.provision :hostmanager
    config.hostmanager.aliases = Catapult::Command.dev_redhat_hosts
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/catapult", type: "nfs"
    # sync the repositories folder for local access from the host
    config.vm.synced_folder "repositories", "/var/www/repositories", type: "nfs"
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mysql","#{Catapult::Command.configuration_user["settings"]["software_validation"]}"]
  end

  # test => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-test-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["test"]["servers"]["redhat"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["test","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","apache"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-test-redhat-mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["test"]["servers"]["redhat_mysql"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["test","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mysql"]
  end

  # qc => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["qc"]["servers"]["redhat"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["qc","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","apache"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-redhat-mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["qc"]["servers"]["redhat_mysql"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["qc","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mysql"]
  end

  # production => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-production-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["production"]["servers"]["redhat"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["production","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","apache"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-production-redhat-mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "#{Catapult::Command.configuration["environments"]["production"]["servers"]["redhat_mysql"]["slug"]}"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["production","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mysql"]
  end

  # dev => windows
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-windows" do |config|
    config.vm.box = "opentable/win-2012r2-standard-amd64-nocm"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows"]["ip"]
    config.vm.network "forwarded_port", guest: 80, host: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows"]["port_80"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    #config.ssh.insert_key = false
    config.vm.communicator = "winrm"
    config.vm.network "forwarded_port", guest: 3389, host: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows"]["port_3389"]
    # configure hosts file on both the host and guest
    config.vm.provision :hostmanager
    config.hostmanager.aliases = Catapult::Command.dev_windows_hosts
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/catapult"
    # sync the repositories folder for local access from the host
    #config.vm.synced_folder "repositories", "/inetpub/repositories", type: "rsync"
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","iis"], run: "always"
  end

end
