# -*- mode: ruby -*-
# vi: set ft=ruby :


require File.expand_path("../catapult/catapult.rb", __FILE__)


Vagrant.configure("2") do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  # windows
  # virtualbox    https://github.com/devopsgroup-io/atlas-vagrant
  # aws           https://aws.amazon.com/marketplace/pp/B00KQOWCAQ

  # centos
  # virtualbox    https://atlas.hashicorp.com/centos/boxes/7
  # digitalocean  https://developers.digitalocean.com/documentation/v2/#list-all-distribution-images

  # build => bamboo
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-build" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = "1gb"
      provider.ipv6 = true
      provider.private_networking = true
      provider.backups_enabled = true
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["build","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","bamboo"]
  end

  # dev => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-redhat" do |config|
    config.vm.box = "centos/7"
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
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","apache"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-redhat-mysql" do |config|
    config.vm.box = "centos/7"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["redhat_mysql"]["ip"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/catapult", type: "nfs"
    # sync the repositories folder for local access from the host
    config.vm.synced_folder "repositories", "/var/www/repositories", type: "nfs"
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mysql"]
  end

  # test => redhat
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-test-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = Catapult::Command.configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["test"]["servers"]["redhat"]["slug"] || "512mb"
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
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["test"]["servers"]["redhat_mysql"]["slug"] || "512mb"
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
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["qc"]["servers"]["redhat"]["slug"] || "512mb"
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
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["qc"]["servers"]["redhat_mysql"]["slug"] || "512mb"
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
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["production"]["servers"]["redhat"]["slug"] || "512mb"
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
      provider.image = "centos-7-x64"
      provider.region = "nyc3"
      provider.size = Catapult::Command.configuration["environments"]["production"]["servers"]["redhat_mysql"]["slug"] || "512mb"
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
    config.vm.box = "devopsgroup-io/windows_server-2012r2-standard-amd64-nocm"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows"]["ip"]
    config.vm.network "forwarded_port", guest: 80, host: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows"]["port_80"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 1024
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
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-dev-windows-mssql" do |config|
    config.vm.box = "devopsgroup-io/windows_server-2012r2-standard-amd64-nocm"
    config.vm.network "private_network", ip: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows_mssql"]["ip"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 1024
      provider.cpus = 1
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.vm.network "forwarded_port", guest: 3389, host: Catapult::Command.configuration["environments"]["dev"]["servers"]["windows_mssql"]["port_3389"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/catapult"
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["dev","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mssql"], run: "always"
  end

  # test => windows
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-test-windows" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["test"]["servers"]["windows"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-test-windows"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["test"]["servers"]["windows"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["test"]["servers"]["windows"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["test","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","iis"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-test-windows-mssql" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["test"]["servers"]["windows_mssql"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-test-windows-mssql"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["test"]["servers"]["windows_mssql"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["test"]["servers"]["windows_mssql"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["test","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mssql"]
  end

  # qc => windows
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-windows" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["qc"]["servers"]["windows"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-windows"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["qc"]["servers"]["windows"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["qc"]["servers"]["windows"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["qc","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","iis"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-windows-mssql" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["qc"]["servers"]["windows_mssql"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-qc-windows-mssql"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["qc"]["servers"]["windows_mssql"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["qc"]["servers"]["windows_mssql"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["qc","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mssql"]
  end

  # production => windows
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-production-windows" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["production"]["servers"]["windows"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-production-windows"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["production"]["servers"]["windows"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["production"]["servers"]["windows"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["production","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","iis"]
  end
  config.vm.define "#{Catapult::Command.configuration["company"]["name"].downcase}-production-windows-mssql" do |config|
    config.vm.provider :aws do |provider,override|
      provider.keypair_name = "Catapult"
      override.ssh.private_key_path = "secrets/id_rsa"
      override.vm.box = "aws"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      provider.access_key_id = Catapult::Command.configuration["company"]["aws_access_key"]
      provider.secret_access_key = Catapult::Command.configuration["company"]["aws_secret_key"]
      provider.ami = "ami-3f0c4628"
      provider.region = "us-east-1"
      provider.instance_type = Catapult::Command.configuration["environments"]["production"]["servers"]["windows_mssql"]["type"] || "t2.micro"
      provider.tags = {
        "Name" => "#{Catapult::Command.configuration["company"]["name"].downcase}-production-windows-mssql"
      }
      provider.user_data = File.read("provisioners/windows/kickstart.txt").gsub(/{{password}}/, Catapult::Command.configuration["environments"]["production"]["servers"]["windows_mssql"]["admin_password"])
      provider.elastic_ip = true
    end
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.vm.communicator = "winrm"
    config.winrm.username = "Administrator"
    config.winrm.password = Catapult::Command.configuration["environments"]["production"]["servers"]["windows_mssql"]["admin_password"]
    # disable the default vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # configure the provisioner
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", args: ["production","#{Catapult::Command.repo}","#{Catapult::Command.configuration_user["settings"]["gpg_key"]}","mssql"]
  end

end
