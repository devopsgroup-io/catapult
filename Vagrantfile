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


# configure catapult and git
puts "\n"
title = "Catapult Release Management - https://github.com/devopsgroup-io/catapult-release-management"
length = title.size
padding = 5
puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
puts "|".ljust(padding)     + title                + "|".rjust(padding)
puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
puts "\n"
if File.exist?('C:\Program Files (x86)\Git\bin\git.exe')
  git = "\"C:\\Program Files (x86)\\Git\\bin\\git.exe\""
else
  git = "git"
end
remote = `#{git} config --get remote.origin.url`
if remote.include?("devopsgroup-io/release-management.git") || remote.include?("devopsgroup-io/catapult-release-management.git")
  puts "In order to use Catapult Release Management, you must fork the repository so that the committed and encrypted configuration is unique to you! See https://github.com/devopsgroup-io/catapult-release-management for more information."
  puts "\n"
  exit 1
else
  puts "Self updating Catapult:"
  branch = `#{git} rev-parse --abbrev-ref HEAD`
  branch = branch.strip
  repo_this = `#{git} config --get remote.origin.url`
  repo_this_upstream = `#{git} config --get remote.upstream.url`
  repo_upstream = "https://github.com/devopsgroup-io/catapult-release-management.git"
  puts "\nYour repository: #{repo_this}"
  puts "Will sync from: #{repo_upstream}\n\n"
  if repo_this_upstream.empty?
    `#{git} remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
  else
    `#{git} remote rm upstream`
    `#{git} remote add upstream https://github.com/devopsgroup-io/catapult-release-management.git`
  end
  repo_this_develop = `#{git} config --get branch.develop.remote`
  if repo_this_develop.empty?
    `#{git} fetch upstream`
    `#{git} checkout -b develop --track upstream/master`
    `#{git} pull upstream master`
  else
    `#{git} checkout develop`
    `#{git} pull upstream master`
  end
  `#{git} push origin develop`
  `#{git} checkout master`
  `#{git} pull upstream master`
  `#{git} push origin master`
  `#{git} checkout #{branch}`
  puts "\n"
end
# create a git pre-commit hook to ensure no confiuration is committed to develop
FileUtils.mkdir_p(".git/hooks")
File.write('.git/hooks/pre-commit',
'#!/usr/bin/env ruby

if File.exist?(\'C:\Program Files (x86)\Git\bin\git.exe\')
  git = "\"C:\\Program Files (x86)\\Git\\bin\\git.exe\""
else
  git = "git"
end

branch = `#{git} rev-parse --abbrev-ref HEAD`
branch = branch.strip
staged = `#{git} diff --name-only --staged --word-diff=porcelain`
staged = staged.split($/)

if "#{branch}" == "develop"
  if staged.include?("configuration.yml.gpg")
    puts "Please commit configuration.yml.gpg on the master branch. You are on the develop branch, which is meant for contribution back to Catapult and should not contain your configuration files."
    exit 1
  end
  if staged.include?("provisioners/.ssh/id_rsa.gpg")
    puts "Please commit provisioners/.ssh/id_rsa.gpg on the master branch. You are on the develop branch, which is meant for contribution back to Catapult and should not contain your configuration files."
    exit 1
  end
  if staged.include?("provisioners/.ssh/id_rsa.pub.gpg")
    puts "Please commit provisioners/.ssh/id_rsa.pub.gpg on the master branch. You are on the develop branch, which is meant for contribution back to Catapult and should not contain your configuration files."
    exit 1
  end
elsif "#{branch}" == "master"
  unless staged.include?("configuration.yml.gpg") || staged.include?("provisioners/.ssh/id_rsa.gpg") || staged.include?("provisioners/.ssh/id_rsa.pub.gpg")
    puts "You are on the master branch, which is only meant for your configuration files (configuration.yml.gpg, provisioners/.ssh/id_rsa.gpg, provisioners/.ssh/id_rsa.pub.gpg). To contribute to Catapult, please switch to the develop branch."
    exit 1
  end
end

')
File.chmod(0777,'.git/hooks/pre-commit')


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
if configuration_user["settings"]["gpg_key"] == nil || configuration_user["settings"]["gpg_key"].match(/\s/) || configuration_user["settings"]["gpg_key"].length < 20
  puts "\nPlease set your team's gpg_key in configuration-user.yml - spaces are not permitted and must be at least 20 characters.\n\n"
  exit 1
end


require "fileutils"
require "yaml"
puts "\n\nEncryption and decryption of Catapult configuration files:"
puts "\n"
if "#{branch}" == "develop"
  puts " * You are on the develop branch, this branch is automatically synced with Catapult core and is meant to contribute back to the core Catapult project."
  puts " * confiuration.yml.gpg, provisioners/.ssh/id_rsa.gpg, provisioners/.ssh/id_rsa.pub.gpg is checked out from the master branch so that you're able to develop and test."
  puts " * After you're finished on the develop branch, switch to the master branch and discard confiuration.yml.gpg, provisioners/.ssh/id_rsa.gpg, provisioners/.ssh/id_rsa.pub.gpg"
  puts "\n"
  `git checkout --force master -- configuration.yml.gpg`
  `git checkout --force master -- provisioners/.ssh/id_rsa.gpg`
  `git checkout --force master -- provisioners/.ssh/id_rsa.pub.gpg`
  `git reset -- configuration.yml.gpg`
  `git reset -- provisioners/.ssh/id_rsa.gpg`
  `git reset -- provisioners/.ssh/id_rsa.pub.gpg`
elsif "#{branch}" == "master"
  puts " * You are on the master branch, this branch is automatically synced with Catapult core and is meant to commit your unique configuration."
  puts "\n"
  # bootstrap configuration.yml
  # initialize configuration.yml.gpg
  if File.zero?("configuration.yml.gpg")
    `gpg --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml.template`
  end
  if configuration_user["settings"]["gpg_edit"]
    if not File.exist?("configuration.yml")
      # decrypt configuration.yml.gpg as configuration.yml
      `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
    end
    # decrypt configuration.yml.gpg as configuration.yml.compare
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.compare --decrypt configuration.yml.gpg`
    if FileUtils.compare_file('configuration.yml', 'configuration.yml.compare')
      puts "\nconfiguration_user[\"settings\"][\"gpg_edit\"] in configuration-user.yml is set to true."
      puts "\nThere were no changes to configuration.yml, no need to encrypt as this would create a new cipher to commit.\n\n"
    else
      # encrypt configuration.yml as configuration.yml.gpg
      puts "\nconfiguration_user[\"settings\"][\"gpg_edit\"] in configuration-user.yml is set to true."
      puts "\nThere were changes to configuration.yml, encrypting configuration.yml as configuration.yml.gpg. Please commit these changes to the master branch for your team to get the changes.\n\n"
      `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
    end
    FileUtils.rm('configuration.yml.compare')
  else
    # decrypt configuration.yml.gpg as configuration.yml
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
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
  end
end
# decrypt and create objects from configuration.yml file and configuration.yml.template
configuration = YAML.load(`gpg --batch --passphrase "#{configuration_user["settings"]["gpg_key"]}" --decrypt configuration.yml.gpg`)
configuration_example = YAML.load_file("configuration.yml.template")
# ensure version is up-to-date
if configuration["software"]["version"] != configuration_example["software"]["version"]
  puts "\nYour configuration.yml file is out of date. To retain your settings please manually duplicate entries from configuration.yml.template with your specific settings."
  puts "*You may also delete your configuration.yml and re-run any vagrant command to have a vanilla version created.\n\n"
  exit 1
end
# decrypt id_rsa and id_rsa.pub
`gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa --decrypt provisioners/.ssh/id_rsa.gpg`
`gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output provisioners/.ssh/id_rsa.pub --decrypt provisioners/.ssh/id_rsa.pub.gpg`
puts "\n"


# configuration.yml validation
# validate required company fields
if configuration["company"]["name"] == nil
  puts "\nPlease set [\"company\"][\"name\"] in configuration.yml\n\n"
  exit 1
end
if configuration["company"]["cloudflare_api_key"] == nil
  puts "\nPlease set [\"company\"][\"cloudflare_api_key\"] in configuration.yml\n\n"
  exit 1
end
if configuration["company"]["cloudflare_email"] == nil
  puts "\nPlease set [\"company\"][\"cloudflare_email\"] in configuration.yml\n\n"
  exit 1
end
if configuration["company"]["cloudflare_email"] == nil
  puts "\nPlease set [\"company\"][\"cloudflare_email\"] in configuration.yml\n\n"
  exit 1
end
if configuration["company"]["email"] == nil
  puts "\nPlease set [\"company\"][\"email\"] in configuration.yml\n\n"
  exit 1
end
if configuration["company"]["digitalocean_personal_access_token"] == nil
  puts "\nPlease set [\"company\"][\"digitalocean_personal_access_token\"] in configuration.yml\n\n"
  exit 1
end
# validate environments
require "securerandom"
configuration["environments"].each do |environment,data|
  if not configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["user_password"]
    configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["user_password"] = SecureRandom.urlsafe_base64(16)
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
    File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
  end
  if not configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["root_password"]
    configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["root_password"] = SecureRandom.urlsafe_base64(16)
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
    File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
  end
  if not configuration["environments"]["#{environment}"]["software"]["drupal"]["admin_password"]
    configuration["environments"]["#{environment}"]["software"]["drupal"]["admin_password"] = SecureRandom.urlsafe_base64(16)
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
    File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
  end
  if not configuration["environments"]["#{environment}"]["software"]["wordpress"]["admin_password"]
    configuration["environments"]["#{environment}"]["software"]["wordpress"]["admin_password"] = SecureRandom.urlsafe_base64(16)
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
    File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
    `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
  end
end
# validate websites
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


# if upstream servers are provisioned, write server ip addresses to configuration.yml for use in database configuration files
require "json"
require "net/ssh"
uri = URI("https://api.digitalocean.com/v2/droplets")
Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
  request = Net::HTTP::Get.new uri.request_uri
  request.basic_auth "#{configuration["company"]["digitalocean_personal_access_token"]}", ""
  response = http.request request # Net::HTTPResponse object
  droplets = JSON.parse(response.body)
  droplets = droplets["droplets"]
  configuration["environments"].each do |environment,data|
    unless environment == "dev"
      if not configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip"]
        droplet = droplets.find { |d| d['name'] == "#{configuration["company"]["name"]}-#{environment}-redhat" }
        unless droplet == nil
          # puts droplet
          configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip"] = droplet["networks"]["v4"].first["ip_address"]
          `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
          File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
          `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
        end
      end
      if not configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip"]
        droplet = droplets.find { |d| d['name'] == "#{configuration["company"]["name"]}-#{environment}-redhat-mysql" }
        unless droplet == nil
          # puts droplet
          configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip"] = droplet["networks"]["v4"].first["ip_address"]
          `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml --decrypt configuration.yml.gpg`
          File.open('configuration.yml', 'w') {|f| f.write configuration.to_yaml }
          `gpg --verbose --batch --yes --passphrase "#{configuration_user["settings"]["gpg_key"]}" --output configuration.yml.gpg --armor --cipher-algo AES256 --symmetric configuration.yml`
        end
      end
    end
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
  puts "\n\nAvailable websites legend:"
  puts "\n[http response codes]"
  puts "\n * 200 ok, 301 moved permanently, 302 found, 400 bad request, 401 unauthorized, 403 forbidden, 404 not found, 500 internal server error, 502 bad gateway, 503 service unavailable, 504 gateway timeout"
  puts " * http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html"
  puts "\n[cert signature algorithm]"
  puts "\n * https://www.openssl.org/docs/apps/ciphers.html"
  puts "\n\n\nAvailable websites:"
  puts "".ljust(30) + "[software]".ljust(15) + "[dev.]".ljust(22) + "[test.]".ljust(22) + "[qc.]".ljust(22) + "[production / cert expiry, signature algorithm, common name]".ljust(80) + "[alexa rank, 3m delta]".ljust(26)

  configuration["websites"].each do |service,data|
    puts "\n[#{service}]"
    configuration["websites"]["#{service}"].each do |instance|
      # count websites
      totalwebsites = totalwebsites + 1
      # start new row
      row = Array.new
      # get domain name
      row.push(" * #{instance["domain"]}".ljust(29))
      # get software
      row.push((instance["software"] || "").ljust(14))
      # get http response code per environment
      configuration["environments"].each do |environment,data|
        response = nil
        if ["production"].include?("#{environment}")
          environment = nil
        else
          environment = "#{environment}."
        end
        begin
          def http_repsonse(uri_str, limit = 10)
            if limit == 0
              row.push("loop".ljust(7))
            else
              response = Net::HTTP.get_response(URI(uri_str))
              case response
              when Net::HTTPSuccess then
                return response.code
              when Net::HTTPRedirection then
                location = response['location']
                http_repsonse(location, limit - 1)
              else
                return response.code
              end
            end
          end
          row.push(http_repsonse("http://#{environment}#{instance["domain"]}").ljust(4))
        rescue SocketError
          row.push("down".ljust(4))
        rescue EOFError
          row.push("down".ljust(4))
        rescue OpenSSL::SSL::SSLError
          row.push("err".ljust(4))
        rescue Exception => ex
          row.push("#{ex.class}".ljust(4))
        end
        # nslookup production top-level domain
        begin
          row.push((Resolv.getaddress "#{environment}#{instance["domain"]}").ljust(16))
        rescue
          row.push("down".ljust(16))
        end
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
        row.push("cannot read cert, missing local cipher?".ljust(57))
      rescue Exception => ex
        row.push("#{ex.class}".ljust(57))
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
  puts "\n[total]"
  row.push(" #{totalwebsites}")
  puts row.join(" ")
  puts "\n\n\n"
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
  config.vm.define "#{configuration["company"]["name"]}-dev-redhat-mysql" do |config|
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
  config.vm.define "#{configuration["company"]["name"]}-test-redhat-mysql" do |config|
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
  config.vm.define "#{configuration["company"]["name"]}-qc-redhat-mysql" do |config|
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
  config.vm.define "#{configuration["company"]["name"]}-production-redhat-mysql" do |config|
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


  config.vm.define "#{configuration["company"]["name"]}-dev-windows" do |config|
    config.vm.box = "opentable/win-2012r2-standard-amd64-nocm"
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
