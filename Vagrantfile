# -*- mode: ruby -*-
# vi: set ft=ruby :


# check for vagrant plugins
unless Vagrant.has_plugin?("vagrant-digitalocean")
  raise 'vagrant-hostmanager is not installed, please run "vagrant plugin install vagrant-digitalocean"'
end
unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise 'vagrant-hostmanager is not installed, please run "vagrant plugin install vagrant-hostmanager"'
end


# require vm name on up and provision
if ["up","provision"].include?(ARGV[0])
  if ARGV.length == 1
    puts "\nYou must use 'vagrant #{ARGV[0]} <name>', run 'vagrant status' to view VM <name>s.\n\n"
    exit 1
  end
end


# print intro
puts "\n"
title = "Catapult Release Management - https://github.com/devopsgroup-io/catapult-release-management"
length = title.size
padding = 5
puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
puts "|".ljust(padding)     + title                + "|".rjust(padding)
puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
# self update release management
puts "\n"
if File.exist?('C:\Program Files (x86)\Git\bin\git.exe')
  remote = `"C:\\Program Files (x86)\\Git\\bin\\git.exe" config --get remote.origin.url`
  if remote.include?("devopsgroup-io/release-management.git") || remote.include?("devopsgroup-io/catapult-release-management.git")
    puts "In order to use Catapult Release Management, you must fork the repository so that the committed and encrypted configuration is unique to you! See https://github.com/devopsgroup-io/catapult-release-management for more information."
    puts "\n"
    exit 1
  else
    puts "Self updating Catapult Release Management..."
    repo_this = `"C:\\Program Files (x86)\\Git\\bin\\git.exe config --get remote.origin.url`
    repo_this_upstream = `"C:\\Program Files (x86)\\Git\\bin\\git.exe config --get remote.upstream.url`
    repo_upstream = "https://github.com/devopsgroup-io/catapult-release-management.git"
    puts "\nYour repository: #{repo_this}"
    puts "Will sync from: #{repo_upstream}\n\n"
    if repo_this_upstream.empty?
      `"C:\\Program Files (x86)\\Git\\bin\\git.exe remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
    else
      `"C:\\Program Files (x86)\\Git\\bin\\git.exe remote rm upstream`
      `"C:\\Program Files (x86)\\Git\\bin\\git.exe remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
    end
    `"C:\\Program Files (x86)\\Git\\bin\\git.exe pull upstream master`
    `"C:\\Program Files (x86)\\Git\\bin\\git.exe push origin master`
    puts "\n"
  end
else
  remote = `git config --get remote.origin.url`
  if remote.include?("devopsgroup-io/release-management.git") || remote.include?("devopsgroup-io/catapult-release-management.git")
    puts "In order to use Catapult Release Management, you must fork the repository so that the committed and encrypted configuration is unique to you! See https://github.com/devopsgroup-io/catapult-release-management for more information."
    puts "\n"
    exit 1
  else
    puts "Self updating Catapult Release Management..."
    repo_this = `git config --get remote.origin.url`
    repo_this_upstream = `git config --get remote.upstream.url`
    repo_upstream = "https://github.com/devopsgroup-io/catapult-release-management.git"
    puts "\nYour repository: #{repo_this}"
    puts "Will sync from: #{repo_upstream}\n\n"
    if repo_this_upstream.empty?
      `git remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
    else
      `git remote rm upstream`
      `git remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
    end
    `git pull upstream master`
    `git push origin master`
    puts "\n"
  end
end


# bootstrap configuration-user.yml
require "fileutils"
require "yaml"
# generate configuration-user.yml file if it does not exist
if not File.exist?("configuration-user.yml")
  FileUtils.cp("configuration-user.yml.template", "configuration-user.yml")
end
# parse configuration-user.yml and configuration-user.yml.template file
configuration_user = YAML.load_file("configuration-user.yml")
configuration_user_example = YAML.load_file("configuration-user.yml.template")
# ensure version is up-to-date
if configuration_user["settings"]["version"] != configuration_user_example["settings"]["version"]
  puts "\nYour configuration-user.yml file is out of date. To retain your settings please manually merge entries from configuration-user.yml.template to configuration-user.yml with your specific settings."
  puts "*You may also delete your configuration-user.yml and re-run any vagrant command to have a vanilla version created.\n\n"
  exit 1
end
# check for required fields
if configuration_user["settings"]["gpg_key"] == "" || configuration_user["settings"]["gpg_key"].match(/\s/) || configuration_user["settings"]["gpg_key"].length < 20
  puts "\nPlease set your team's gpg_key in configuration-user.yml - spaces are not permitted and must be at least 20 characters.\n\n"
  exit 1
end


# bootstrap configuration.yml
require "fileutils"
require "yaml"
# initialize configuration.yml.gpg
if File.zero?("configuration.yml.gpg")
  `gpg --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml.template`
end
if configuration_user["settings"]["gpg_edit"]
  if not File.exist?("configuration.yml")
    # decrypt configuration.yml.gpg as configuration.yml
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
  end
  # encrypt configuration.yml as configuration.yml.gpg
  `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
else
  # decrypt configuration.yml.gpg as configuration.yml
  `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
end
# parse configuration.yml file and configuration.yml.template
configuration = YAML.load(`gpg --batch --passphrase "#{configuration_user["settings"]["gpg_key"]}" --decrypt configuration.yml.gpg`)
configuration_example = YAML.load_file("configuration.yml.template")
# ensure version is up-to-date
if configuration["software"]["version"] != configuration_example["software"]["version"]
  puts "\nYour configuration.yml file is out of date. To retain your settings please manually duplicate entries from configuration.yml.template with your specific settings."
  puts "*You may also delete your configuration.yml and re-run any vagrant command to have a vanilla version created.\n\n"
  exit 1
end


# bootstrap ssh keys
# id_rsa.gpg and id_rsa.pub.gpg will be blank initially
if File.zero?("provisioners/.ssh/id_rsa.gpg") && File.zero?("provisioners/.ssh/id_rsa.pub.gpg")
  # once the ssh keys are placed, encrypt them
  if File.exist?("provisioners/.ssh/id_rsa") && File.exist?("provisioners/.ssh/id_rsa.pub")
    # encrypt id_rsa and id_rsa.pub
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa.gpg --armor --cipher-algo AES256 --symmetric provisioners/.ssh/id_rsa`
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa.pub.gpg --armor --cipher-algo AES256 --symmetric provisioners/.ssh/id_rsa.pub`
  else
    puts "\nPlease place your team's ssh public (id_rsa.pub) and private key (id_rsa.pub) in provisioners/.ssh\n\n"
    exit 1
  end
elsif
  # decrypt id_rsa and id_rsa.pub
  `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa --decrypt provisioners/.ssh/id_rsa.gpg`
  `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa.pub --decrypt provisioners/.ssh/id_rsa.pub.gpg`
end


# configuration.yml validation
# check for required fields
require "net/ssh"
# validate digitalocean_personal_access_token
if configuration["company"]["digitalocean_personal_access_token"] == ""
  puts "\nPlease set your company's digitalocean_personal_access_token in configuration.yml.\n\n"
  exit 1
end
configuration["websites"].each do |service,data|
  domains = Array.new
  domains_sorted = Array.new
  configuration["websites"]["#{service}"].each do |instance|
    domains.push("#{instance["domain"]}")
    domains_sorted.push("#{instance["domain"]}")
    # validate repo user
    repo = instance["repo"].split("@")
    if repo[0] != "git"
      puts "\nThere is an error in your configuration.yml file."
      puts "\nThe repo for websites => #{service} => domain => #{instance["domain"]} is invalid, the format must be git@github.com:devopsgroup-io/devopsgroup-io.git\n\n"
      exit 1
    end
    # validate repo bitbucket.org or github.com
    repo = repo[1].split(":")
    if "#{repo[0]}" != "bitbucket.org" && "#{repo[0]}" != "github.com"
      puts "\nThere is an error in your configuration.yml file."
      puts "\nThe repo for websites => #{service} => domain => #{instance["domain"]} is invalid, it must either be a bitbucket.org or github.com repository.\n\n"
      exit 1
    end
    # validate repo connection
    Net::SSH.start(
      "github.com","git",
      :host_key => "ssh-rsa",
      :keys => ["provisioners/.ssh/id_rsa"],
      #:verbose => :debug
    ) do |session|
      #puts session.inspect
    end
    # validate webroot
    if not "#{instance["webroot"]}" == ""
      if not "#{instance["webroot"]}"[-1,1] == "/"
        puts "\nThere is an error in your configuration.yml file."
        puts "\nThe webroot for websites => #{service} => domain => #{instance["domain"]} is invalid, it must include a trailing slash.\n\n"
        exit 1
      end
    end
  end
  # ensure domains are in alpha order
  domains_sorted = domains_sorted.sort
  if domains != domains_sorted
    puts "\nThere is an error in your configuration.yml file."
    puts "\nThe domains in configuration.yml are not in alpha order for websites => #{service} - please adjust.\n\n"
    exit 1
  end
end


# create arrays of domains for localdev hosts file
redhathostsfile = Array.new
configuration["websites"]["apache"].each do |instance|
  redhathostsfile.push("dev.#{instance["domain"]}")
  redhathostsfile.push("www.dev.#{instance["domain"]}")
end
windowshostsfile = Array.new
configuration["websites"]["iis"].each do |instance|
  windowshostsfile.push("dev.#{instance["domain"]}")
  windowshostsfile.push("www.dev.#{instance["domain"]}")
end


if ["status"].include?(ARGV[0])
  # vagrant status binding
  require "nokogiri" # required for alexa
  require "open-uri" # required for alexa
  require "net/http" # required for nslookup
  require "socket"   # required for ssl cert lookup
  require "openssl"  # required for ssl cert lookup
  totalwebsites = 0
  # start a new row
  puts "Available websites legend:"
  puts "[http response codes]"
  puts " 200 ok, 301 moved permanently, 302 found, 400 bad request, 401 unauthorized, 403 forbidden, 404 not found"
  puts " 500 internal server error, 502 bad gateway, 503 service unavailable, 504 gateway timeout"
  puts " http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html"
  puts "[cert signature algorithm]"
  puts " https://www.openssl.org/docs/apps/ciphers.html"
  puts "\n"
  puts "Available websites:"
  puts "".ljust(30) + "[software]".ljust(15) + "[dev.]".ljust(8) + "[test.]".ljust(8) + "[qc.]".ljust(8) + "[production / nslookup / cert expiry, signature algorithm, common name]".ljust(82) + "[alexa rank, 3m delta]".ljust(26)

  configuration["websites"].each do |service,data|
    puts "[#{service}]"
    configuration["websites"]["#{service}"].each do |instance|
      # count websites
      totalwebsites = totalwebsites + 1
      # start a new row
      row = Array.new
      # get domain name
      row.push(instance["domain"].ljust(29))
      # get software
      row.push((instance["software"] || "").ljust(14))
      # get http response code per environment
      configuration["environments"].each do |environment,data|
        response = nil
        if ["production"].include?("#{environment}")
          environment = ""
        else
          environment = "#{environment}."
        end
        begin
          Net::HTTP.start("#{environment}#{instance["domain"]}", 80) {|http|
            response = http.head("/")
          }
          row.push(response.code.ljust(7))
        rescue
          row.push("down".ljust(7))
        end
      end
      # nslookup production top-level domain
      begin
        row.push((Resolv.getaddress "#{instance["domain"]}").ljust(15))
      rescue
        row.push("down".ljust(15))
      end
      # ssl cert lookup
      begin 
        timeout(1) do
          tcp_client = TCPSocket.new("#{instance["domain"]}", 443)
          ssl_context = OpenSSL::SSL::SSLContext.new()
          ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
          ssl_client.connect
          cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
          ssl_client.sysclose
          tcp_client.close
          #http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/X509/Certificate.html
          date = Date.parse((cert.not_after).to_s)
          row.push("#{date.strftime('%F')} #{cert.signature_algorithm} #{cert.subject.to_a.select{|name, _, _| name == 'CN' }.first[1]}".downcase.ljust(57))
        end
      rescue SocketError
        row.push("down".ljust(57))
      rescue Errno::ECONNREFUSED
        row.push("connection refused".ljust(57))
      rescue Errno::ECONNRESET
        row.push("connection reset".ljust(57))
      rescue Timeout::Error
        row.push("no 443 listener".ljust(57))
      rescue OpenSSL::SSL::SSLError
        row.push("ssl error - cannot read cert".ljust(57))
      rescue Exception => ex
        row.push("error: #{ex.class} #{ex.message}".ljust(57))
      end
      # alexa rank and 3 month deviation
      begin
        uri = URI("http://data.alexa.com/data?cli=10&url=#{instance["domain"]}")
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new uri.request_uri
          response = http.request request # Net::HTTPResponse object
          response = Nokogiri::XML(response.body)
          if "#{response.xpath('//ALEXA//SD//POPULARITY')}" != ""
            response.xpath('//ALEXA//SD//POPULARITY').each do |attribute|
              row.push(attribute["TEXT"].to_s.reverse.gsub(/...(?=.)/,'\&,').reverse.ljust(11))
            end
          else
            row.push("".ljust(11))
          end
          if "#{response.xpath('//ALEXA//SD//RANK')}" != ""
            response.xpath('//ALEXA//SD//RANK').each do |attribute|
                row.push(attribute["DELTA"].ljust(13))
            end
          else
            row.push("".ljust(13))
          end
        end
      end
      puts row.join(" ")
    end
  end
  # start a new row
  row = Array.new
  puts "[total]"
  row.push("#{totalwebsites}")
  puts row.join(" ")
  puts "\n"
end


# server vms
Vagrant.configure("2") do |config|


  # vagrant hostmanager plugin configuration
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true


  # localdev servers
  config.vm.define "#{configuration["company"]["name"]}-dev-redhat" do |config|
    config.vm.box = "chef/centos-7.0"
    config.vm.network "private_network", ip: configuration["environments"]["dev"]["servers"]["redhat"]["ip"]
    config.vm.network "forwarded_port", guest: 80, host: configuration["environments"]["dev"]["servers"]["redhat"]["port_80"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    config.vm.provision :hostmanager
    config.hostmanager.aliases = redhathostsfile
    config.vm.synced_folder ".", "/vagrant", type: "nfs"
    config.vm.synced_folder "repositories", "/var/www/repositories", type: "nfs"
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["dev","#{configuration_user["settings"]["git_pull"]}","#{configuration_user["settings"]["production_rsync"]}","#{configuration_user["settings"]["software_validation"]}"]
  end
  config.vm.define "#{configuration["company"]["name"]}-dev-redhat_mysql" do |config|
    config.vm.box = "chef/centos-7.0"
    config.vm.network "private_network", ip: configuration["environments"]["dev"]["servers"]["redhat_mysql"]["ip"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    config.vm.synced_folder ".", "/vagrant", type: "nfs"
    config.vm.provision :hostmanager
    config.vm.provision "shell", path: "provisioners/redhat_mysql/provision.sh", args: ["dev"]
  end


  # test servers
  config.vm.define "#{configuration["company"]["name"]}-test-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["test","true","false","true"]
  end
  config.vm.define "#{configuration["company"]["name"]}-test-redhat_mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat_mysql/provision.sh", args: ["test"]
  end


  # quality control servers
  config.vm.define "#{configuration["company"]["name"]}-qc-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["qc","true","false","true"]
  end
  config.vm.define "#{configuration["company"]["name"]}-qc-redhat_mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat_mysql/provision.sh", args: ["qc"]
  end


  # production servers
  config.vm.define "#{configuration["company"]["name"]}-production-redhat" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat/provision.sh", args: ["production","true","false","true"]
  end
  config.vm.define "#{configuration["company"]["name"]}-production-redhat_mysql" do |config|
    config.vm.provider :digital_ocean do |provider,override|
      override.ssh.private_key_path = "provisioners/.ssh/id_rsa"
      override.vm.box = "digital_ocean"
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      provider.token = configuration["company"]["digitalocean_personal_access_token"]
      provider.image = "centos-7-0-x64"
      provider.region = "nyc3"
      provider.size = "512mb"
      provider.ipv6 = true
      provider.backups_enabled = true
    end
    config.vm.synced_folder ".", "/vagrant", type: "rsync"
    config.vm.provision "shell", path: "provisioners/redhat_mysql/provision.sh", args: ["production"]
  end


  config.vm.define "windows" do |config|
    config.vm.box = "opentable/win-2008r2-standard-amd64-nocm"
    config.vm.network "private_network", ip: configuration["environments"]["dev"]["servers"]["windows"]["ip"]
    config.vm.network "forwarded_port", guest: 80, host: configuration["environments"]["dev"]["servers"]["redhat"]["port_80"]
    config.vm.provider :virtualbox do |provider|
      provider.memory = 512
      provider.cpus = 1
    end
    config.vm.synced_folder "repositories", "/inetpub/repositories"
    config.vm.provision :hostmanager
    config.hostmanager.aliases = windowshostsfile
    config.vm.provision "shell", path: "provisioners/windows/provision.ps1", run: "always"
    # windows specific configuration
    config.vm.guest = :windows
    config.vm.boot_timeout = 60 * 7
    config.ssh.insert_key = false
    config.vm.communicator = "winrm"
    config.vm.network "forwarded_port", guest: 3389, host: configuration["environments"]["dev"]["servers"]["redhat"]["port_3389"]
  end


end
