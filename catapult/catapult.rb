# -*- mode: ruby -*-
# vi: set ft=ruby :


class Colors
   NOCOLOR = "\033[0m"
   RED = "\033[1;31;40m"
   GREEN = "\033[1;32;40m"
   YELLOW = "\033[1;33;40m"
   WHITE = "\033[1;37;40m"
end
class String
   def color(color)
      return color + self + Colors::NOCOLOR
   end
end


module Catapult
  class Command


    # define module => class attributes
    class << self
      attr_accessor :configuration
      attr_accessor :configuration_user
      attr_accessor :dev_redhat_hosts
      attr_accessor :dev_windows_hosts
      attr_accessor :repo
    end


    # puts intro
    puts "\n"
    title = "Catapult - https://github.com/devopsgroup-io/catapult"
    length = title.size
    padding = 5
    puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
    puts "|".ljust(padding)     + title                + "|".rjust(padding)
    puts "+".ljust(padding,"-") + "".ljust(length,"-") + "+".rjust(padding,"-")
    puts "\n"


    # libraries
    require "fileutils"
    require "json"
    require "net/ssh"
    require "net/http"
    require "open-uri"
    require "openssl"
    require "resolv"
    require "securerandom"
    require "yaml"


    # format errors
    def Command::catapult_exception(error)
      begin
        raise error
      rescue => exception
        puts "\n\n"
        title = "Catapult Error:"
        length = title.size
        padding = 5
        puts "+".ljust(padding,"!") + "".ljust(length,"!") + "+".rjust(padding,"!")
        puts "|".ljust(padding)     + title                + "|".rjust(padding)
        puts "+".ljust(padding,"!") + "".ljust(length,"!") + "+".rjust(padding,"!")
        puts "\n"
        puts exception.message
        puts "\n"
        puts "Please correct the error then re-run your vagrant command."
        puts "See https://github.com/devopsgroup-io/catapult for more information."
        if File.exist?('.lock')
          File.delete('.lock')
        end
        exit 1
      end
    end


    # ensure the user is in the correct directory when running vagrant commands to prevent git from pulling in catapult upstream master into repositories
    unless File.exist?('LICENSE.txt') && File.exist?('README.md') && File.exist?('VERSION.yml')
      catapult_exception("You are outside of the Catapult root, please change to the Catapult root directory.")
    end


    # set variables based on operating system
    # windows
    if (RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/)
      if File.exist?('C:\Program Files (x86)\Git\bin\git.exe')
        @git = "\"C:\\Program Files (x86)\\Git\\bin\\git.exe\""
      elsif File.exist?('C:\Program Files\Git\bin\git.exe')
        @git = "\"C:\\Program Files\\Git\\bin\\git.exe\""
      else
        catapult_exception("Git is not installed at C:\\Program Files (x86)\\Git\\bin\\git.exe or C:\\Program Files\\Git\\bin\\git.exe")
      end
      begin
         require "Win32/Console/ANSI"
      rescue LoadError
         catapult_exception('win32console is not installed, please run "gem install win32console"')
      end
    # others
    elsif (RbConfig::CONFIG['host_os'] =~ /darwin|mac os|linux|solaris|bsd/)
      @git = "git"
    else
      catapult_exception("Cannot detect your operating system, please submit an issue at https://github.com/devopsgroup-io/catapult")
    end



    # locking in order to prevent multiple executions occurring at once (e.g. competing command line and Bamboo executions)
    if File.exist?('.lock')
      catapult_exception("The .lock file is present in this directory. This indicates that another process, such as provisioning, may be under way in another session or that a process ended unexpectedly. Once verifying that no conflict exists, remove the .lock file and try again.")
    end
    FileUtils.touch('.lock')


    # check for an internet connection
    dns_resolver = Resolv::DNS.new()
    begin
      dns_resolver.getaddress("google.com")
    rescue Resolv::ResolvError => e
      catapult_exception("Please check your internet connection, unable to reach google.com")
    end


    # check for vagrant plugins
    unless Vagrant.has_plugin?("vagrant-aws")
      catapult_exception('vagrant-aws is not installed, please run "vagrant plugin install vagrant-aws"')
    end
    unless Vagrant.has_plugin?("vagrant-digitalocean")
      catapult_exception('vagrant-digitalocean is not installed, please run "vagrant plugin install vagrant-digitalocean"')
    end
    unless Vagrant.has_plugin?("vagrant-hostmanager")
      catapult_exception('vagrant-hostmanager is not installed, please run "vagrant plugin install vagrant-hostmanager"')
    end
    unless Vagrant.has_plugin?("vagrant-vbguest")
      catapult_exception('vagrant-vbguest is not installed, please run "vagrant plugin install vagrant-vbguest"')
    end


    # require vm name on up and provision
    if ["up","provision"].include?(ARGV[0])
      if ARGV.length == 1
        catapult_exception("You must use 'vagrant #{ARGV[0]} <name>', run 'vagrant status' to view VM <name>s.")
      end
    end


    # configure catapult and git
    remote = `#{@git} config --get remote.origin.url`
    if remote.include?("devopsgroup-io/")
      catapult_exception("In order to use Catapult Release Management, you must fork the repository so that the committed and encrypted configuration is unique to you! See https://github.com/devopsgroup-io/catapult for more information.")
    else
      puts "\n\nSelf updating Catapult:\n".color(Colors::WHITE)
      `#{@git} fetch`
      # get current branch
      branch = `#{@git} rev-parse --abbrev-ref HEAD`.strip
      # get current repo
      @repo = `#{@git} config --get remote.origin.url`.strip
      puts " * Your repository: #{@repo}"
      # set the correct upstream
      repo_upstream = `#{@git} config --get remote.upstream.url`.strip
      repo_upstream_url = "https://github.com/devopsgroup-io/catapult.git"
      puts " * Will sync from: #{repo_upstream}"
      if repo_upstream.empty?
        `#{@git} remote add upstream #{repo_upstream_url}`
      else
        `#{@git} remote rm upstream`
        `#{@git} remote add upstream #{repo_upstream_url}`
      end
      # get a list of branches from origin
      @branches = `#{@git} ls-remote #{@repo}`.split(/\n/).reject(&:empty?)
      # halt if there is no master branch
      if not @branches.find { |element| element.include?("refs/heads/master") }
        catapult_exception("Cannot find the master branch for your Catapult's fork, please fork again or manually correct.")
      end
      # create the release branch if it does not yet exist
      if not @branches.find { |element| element.include?("refs/heads/release") }
        `#{@git} checkout master`
        `#{@git} checkout -b release`
        `#{@git} push origin release`
      end
      # create the develop branch if it does not yet exist
      if not @branches.find { |element| element.include?("refs/heads/develop") }
        `#{@git} fetch upstream`
        `#{@git} checkout -b develop --track upstream/master`
        `#{@git} pull upstream master`
        `#{@git} push origin develop`
      end
      # create the develop-catapult branch if it does not yet exist
      if not @branches.find { |element| element.include?("refs/heads/develop-catapult") }
        `#{@git} fetch upstream`
        `#{@git} checkout -b develop-catapult --track upstream/master`
        `#{@git} pull upstream master`
        `#{@git} push origin develop-catapult`
      end
      # if on the master or release branch, stop user
      if "#{branch}" == "master" || "#{branch}" == "release"
        catapult_exception(""\
          "You are on the #{branch} branch, all interaction should be done from either the develop or develop-catapult branch."\
          " * The develop branch is running in test"\
          " * The release branch is running in qc"\
          " * The master branch is running in production"\
          "To move your configuration from environment to environment, create pull requests (develop => release, release => master)."\
        "")
      end
      puts "\n * Configuring the #{branch} branch:\n\n"
      # if on the develop branch, update from catapult core
      if "#{branch}" == "develop"
        `#{@git} pull origin develop`
        # only self update from catapult core if the same MAJOR
        `#{@git} fetch upstream`
        @version_this = YAML.load_file("VERSION.yml")
        @version_this_integer = @version_this["version"].to_i
        @version_upstream = YAML.load(`#{@git} show upstream/master:VERSION.yml`)
        @version_upstream_integer = @version_upstream["version"].to_i
        if @version_upstream_integer > @version_this_integer
          puts "\n"
          puts "#{@version_upstream["major"]["notice"]}".color(Colors::RED)
          puts "#{@version_upstream["major"]["description"]}".color(Colors::YELLOW)
          puts " * This Catapult instance is version #{@version_this["version"]}"
          puts " * Catapult version #{@version_upstream["version"]} is available"
          puts "The upgrade path warning from MAJOR version #{@version_this["version"].to_i} to #{@version_upstream["version"].to_i} is:"
          puts " * #{@version_upstream["major"][@version_upstream_integer][@version_this_integer]}"
          puts "Given that you are prepared for the above, please follow these instructions to upgrade manually from within the root of Catapult:"
          puts " * `git pull upstream master`"
          puts " * `git push origin develop`"
          puts "\n"
        else
          `#{@git} pull upstream master`
          `#{@git} push origin develop`
        end
      end
      # if on the develop-catapult branch, update from catapult core, and checkout secrets from develop
      if "#{branch}" == "develop-catapult"
        `#{@git} checkout develop -- secrets/configuration.yml.gpg`
        `#{@git} checkout develop -- secrets/id_rsa.gpg`
        `#{@git} checkout develop -- secrets/id_rsa.pub.gpg`
        `#{@git} reset HEAD secrets/configuration.yml.gpg`
        `#{@git} reset HEAD secrets/id_rsa.gpg`
        `#{@git} reset HEAD secrets/id_rsa.pub.gpg`
        `#{@git} pull origin develop-catapult`
        `#{@git} pull upstream master`
        `#{@git} push origin develop-catapult`
      end
    end
    # create a git pre-commit hook to ensure only configuration is committed to only the develop branch
    FileUtils.mkdir_p(".git/hooks")
    File.write('.git/hooks/pre-commit',
    '#!/usr/bin/env ruby

    if File.exist?(\'C:\Program Files (x86)\Git\bin\git.exe\')
      git = "\"C:\\Program Files (x86)\\Git\\bin\\git.exe\""
    elsif File.exist?(\'C:\Program Files\Git\bin\git.exe\')
      git = "\"C:\\Program Files\\Git\\bin\\git.exe\""
    else
      git = "git"
    end

    branch = `#{git} rev-parse --abbrev-ref HEAD`.strip
    staged = `#{git} diff --name-only --staged --word-diff=porcelain`
    staged = staged.split($/)

    if "#{branch}" == "develop-catapult"
      unless staged.include?("VERSION.yml")
        puts "Please increment the version in VERSION.yml for every commit, see http://semver.org/ for more information."
        exit 1
      end
      if staged.include?("secrets/configuration.yml.gpg")
        puts "Please commit secrets/configuration.yml.gpg on the develop branch. You are on the develop-catapult branch, which is meant for contribution back to Catapult and should not contain your configuration files."
        exit 1
      end
      if staged.include?("secrets/id_rsa.gpg")
        puts "Please commit secrets/id_rsa.gpg on the develop branch. You are on the develop-catapult branch, which is meant for contribution back to Catapult and should not contain your configuration files."
        exit 1
      end
      if staged.include?("secrets/id_rsa.pub.gpg")
        puts "Please commit secrets/id_rsa.pub.gpg on the develop branch. You are on the develop-catapult branch, which is meant for contribution back to Catapult and should not contain your configuration files."
        exit 1
      end
    elsif "#{branch}" == "develop"
      unless staged.include?("secrets/configuration.yml.gpg") || staged.include?("secrets/id_rsa.gpg") || staged.include?("secrets/id_rsa.pub.gpg")
        puts "You are on the develop branch, which is only meant for your configuration files (secrets/configuration.yml.gpg, secrets/id_rsa.gpg, secrets/id_rsa.pub.gpg)."
        puts "To contribute to Catapult, please switch to the develop-catapult branch."
        exit 1
      end
    elsif "#{branch}" == "release"
      unless staged.include?("secrets/configuration.yml.gpg") || staged.include?("secrets/id_rsa.gpg") || staged.include?("secrets/id_rsa.pub.gpg")
        puts "You are trying to commit directly to the release branch, please create a pull request from develop into release instead."
        exit 1
      end
    elsif "#{branch}" == "master"
      unless staged.include?("secrets/configuration.yml.gpg") || staged.include?("secrets/id_rsa.gpg") || staged.include?("secrets/id_rsa.pub.gpg")
        puts "You are trying to commit directly to the master branch, please create a pull request from release into master instead."
        exit 1
      else 
        puts "To contribute to Catapult, please switch to the develop-catapult branch."
        exit 1
      end
    end

    ')
    File.chmod(0777,'.git/hooks/pre-commit')


    # bootstrap secrets/configuration-user.yml
    # generate secrets/configuration-user.yml file if it does not exist
    unless File.exist?("secrets/configuration-user.yml")
      FileUtils.cp("secrets/configuration-user.yml.template", "secrets/configuration-user.yml")
    end
    # parse secrets/configuration-user.yml and secrets/configuration-user.yml.template file
    @configuration_user = YAML.load_file("secrets/configuration-user.yml")
    @configuration_user_template = YAML.load_file("secrets/configuration-user.yml.template")
    # check for required fields
    if @configuration_user["settings"]["gpg_key"] == nil || @configuration_user["settings"]["gpg_key"].match(/\s/) || @configuration_user["settings"]["gpg_key"].length < 20
      catapult_exception("Please set your team's gpg_key in secrets/configuration-user.yml - spaces are not permitted and must be at least 20 characters.")
    end


    puts "\n\n\nVerification of encrypted Catapult configuration files:\n".color(Colors::WHITE)
    if "#{branch}" == "develop-catapult"
      puts " * You are on the develop-catapult branch, this branch is automatically synced with Catapult core and is meant to contribute back to the core Catapult project."
      puts " * secrets/configuration.yml.gpg, secrets/id_rsa.gpg, and secrets/id_rsa.pub.gpg are checked out from the develop branch so that you're able to develop and test."
      puts " * After you're finished on the develop-catapult branch, switch to your develop branch and discard secrets/configuration.yml.gpg, secrets/id_rsa.gpg, and secrets/id_rsa.pub.gpg"
      puts "\n"
      `#{@git} checkout --force develop -- secrets/configuration.yml.gpg`
      `#{@git} checkout --force develop -- secrets/id_rsa.gpg`
      `#{@git} checkout --force develop -- secrets/id_rsa.pub.gpg`
      `#{@git} reset -- secrets/configuration.yml.gpg`
      `#{@git} reset -- secrets/id_rsa.gpg`
      `#{@git} reset -- secrets/id_rsa.pub.gpg`
    elsif "#{branch}" == "develop"
      puts " * You are on the develop branch, this branch contains your unique secrets/configuration.yml.gpg, secrets/id_rsa.gpg, and secrets/id_rsa.pub.gpg secrets/configuration."
      puts " * The develop branch is running in the localdev and test environments, please first test then commit your configuration to the develop branch."
      puts " * Once you're satisified with your new configuration in localdev and test, create a pull request from develop into master."
      if @configuration_user["settings"]["gpg_edit"]
        puts " * GPG Edit Mode is enabled at secrets/configuration-user.yml[\"settings\"][\"gpg_edit\"], if there are changes to secrets/configuration.yml, secrets/id_rsa, or secrets/id_rsa.pub, they will be re-encrypted."
      end
      puts "\n"
      # bootstrap secrets/configuration.yml
      # initialize secrets/configuration.yml.gpg
      if File.zero?("secrets/configuration.yml.gpg")
        `gpg --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml.template`
      end
      if @configuration_user["settings"]["gpg_edit"]
        unless File.exist?("secrets/configuration.yml")
          # decrypt secrets/configuration.yml.gpg as secrets/configuration.yml
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
        end
        # decrypt secrets/configuration.yml.gpg as secrets/configuration.yml.compare
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.compare --decrypt secrets/configuration.yml.gpg`
        if FileUtils.compare_file('secrets/configuration.yml', 'secrets/configuration.yml.compare')
          puts "\n * There were no changes to secrets/configuration.yml, no need to encrypt as this would create a new cipher to commit.\n\n"
        else
          puts "\n * There were changes to secrets/configuration.yml, encrypting secrets/configuration.yml as secrets/configuration.yml.gpg. Please commit these changes to the master branch for your team to get the changes.\n\n"
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
        end
        FileUtils.rm('secrets/configuration.yml.compare')
      else
        # decrypt secrets/configuration.yml.gpg as secrets/configuration.yml
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
      end
      # bootstrap ssh keys
      # decrypt id_rsa and id_rsa.pub
      if File.zero?("secrets/id_rsa.gpg") || File.zero?("secrets/id_rsa.pub.gpg")
        if not File.exist?("secrets/id_rsa") || File.zero?("secrets/id_rsa.pub")
          catapult_exception("Please place your team's ssh public (id_rsa.pub) and private key (id_rsa.pub) in the ~/secrets folder.")
        else
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.gpg --armor --cipher-algo AES256 --symmetric secrets/id_rsa`
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub.gpg --armor --cipher-algo AES256 --symmetric secrets/id_rsa.pub`
        end
      end
      if @configuration_user["settings"]["gpg_edit"]
        unless File.exist?("secrets/id_rsa")
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa --decrypt secrets/id_rsa.gpg`
        end
        unless File.exist?("secrets/id_rsa.pub")
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub --decrypt secrets/id_rsa.pub.gpg`
        end
        # decrypt secrets/id_rsa.gpg as secrets/id_rsa.compare
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.compare --decrypt secrets/id_rsa.gpg`
        if FileUtils.compare_file('secrets/id_rsa', 'secrets/id_rsa.compare')
          puts "\n * There were no changes to secrets/id_rsa, no need to encrypt as this would create a new cipher to commit.\n\n"
        else
          puts "\n * There were changes to secrets/id_rsa, encrypting secrets/id_rsa as secrets/id_rsa.gpg. Please commit these changes to the master branch for your team to get the changes.\n\n"
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.gpg --armor --cipher-algo AES256 --symmetric secrets/id_rsa`
        end
        FileUtils.rm('secrets/id_rsa.compare')
        # decrypt secrets/id_rsa.pub.gpg as secrets/id_rsa.pub.compare
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub.compare --decrypt secrets/id_rsa.pub.gpg`
        if FileUtils.compare_file('secrets/id_rsa.pub', 'secrets/id_rsa.pub.compare')
          puts "\n * There were no changes to secrets/id_rsa.pub, no need to encrypt as this would create a new cipher to commit.\n\n"
        else
          puts "\n * There were changes to secrets/id_rsa.pub, encrypting secrets/id_rsa.pub as secrets/id_rsa.pub.gpg. Please commit these changes to the master branch for your team to get the changes.\n\n"
          `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub.gpg --armor --cipher-algo AES256 --symmetric secrets/id_rsa.pub`
        end
        FileUtils.rm('secrets/id_rsa.pub.compare')
      else
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa --decrypt secrets/id_rsa.gpg`
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub --decrypt secrets/id_rsa.pub.gpg`
      end
    end
    # create objects from secrets/configuration.yml.gpg and secrets/configuration.yml.template
    @configuration = YAML.load(`gpg --verbose --batch --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --decrypt secrets/configuration.yml.gpg`)
    if $?.exitstatus > 0
      catapult_exception("Your configuration could not be decrypted, please confirm your team's gpg_key is correct in secrets/configuration-user.yml")
    end
    `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa --decrypt secrets/id_rsa.gpg`
    if $?.exitstatus > 0
      catapult_exception("Your configuration could not be decrypted, please confirm your team's gpg_key is correct in secrets/configuration-user.yml")
    end
    `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/id_rsa.pub --decrypt secrets/id_rsa.pub.gpg`
    if $?.exitstatus > 0
      catapult_exception("Your configuration could not be decrypted, please confirm your team's gpg_key is correct in secrets/configuration-user.yml")
    end
    # load provisioners yaml file
    @provisioners = YAML.load_file("provisioners/provisioners.yml")



    puts "\nVerification of configuration[\"company\"]:\n".color(Colors::WHITE)
    # validate @configuration["company"]
    if @configuration["company"]["name"] == nil
      catapult_exception("Please set [\"company\"][\"name\"] in secrets/configuration.yml")
    end
    if @configuration["company"]["email"] == nil
      catapult_exception("Please set [\"company\"][\"email\"] in secrets/configuration.yml")
    end
    if @configuration["company"]["timezone_redhat"] == nil
      catapult_exception("Please set [\"company\"][\"timezone_redhat\"] in secrets/configuration.yml")
    end
    if @configuration["company"]["timezone_windows"] == nil
      catapult_exception("Please set [\"company\"][\"timezone_windows\"] in secrets/configuration.yml")
    end
    # https://developers.digitalocean.com/documentation/v2/
    if @configuration["company"]["digitalocean_personal_access_token"] == nil
      catapult_exception("Please set [\"company\"][\"digitalocean_personal_access_token\"] in secrets/configuration.yml")
    else
      uri = URI("https://api.digitalocean.com/v2/droplets")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field "Authorization", "Bearer #{@configuration["company"]["digitalocean_personal_access_token"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The DigitalOcean API could not authenticate, please verify [\"company\"][\"digitalocean_personal_access_token\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The DigitalOcean API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * DigitalOcean API authenticated successfully."
          @api_digitalocean = JSON.parse(response.body)
          uri = URI("https://api.digitalocean.com/v2/account/keys")
          Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new uri.request_uri
            request.add_field "Authorization", "Bearer #{@configuration["company"]["digitalocean_personal_access_token"]}"
            response = http.request request
            api_digitalocean_account_keys = JSON.parse(response.body)
            @api_digitalocean_account_key_name = false
            @api_digitalocean_account_key_public_key = false
            api_digitalocean_account_keys["ssh_keys"].each do |key|
              if key["name"] == "Vagrant"
                @api_digitalocean_account_key_name = true
                if "#{key["public_key"].match(/(\w*-\w*\s\S*)/)}" == "#{File.read("secrets/id_rsa.pub").match(/(\w*-\w*\s\S*)/)}"
                  @api_digitalocean_account_key_public_key = true
                end
              end
            end
            unless @api_digitalocean_account_key_name
              catapult_exception("Could not find the SSH Key named \"Vagrant\" in DigitalOcean, please follow the Services Setup for DigitalOcean at https://github.com/devopsgroup-io/catapult#services-setup")
            else
              puts "   - Found the ssh public key \"Vagrant\""
            end
            unless @api_digitalocean_account_key_public_key
              catapult_exception("The SSH Key named \"Vagrant\" in DigitalOcean does not match your Catapult instance's SSH Key at \"secrets/id_rsa.pub\", please follow the Services Setup for DigitalOcean at https://github.com/devopsgroup-io/catapult#services-setup")
            else
              puts "   - The ssh public key \"Vagrant\" matches your secrets/id_rsa.pub ssh public key"
            end
          end
        end
      end
    end
    # https://confluence.atlassian.com/display/BITBUCKET/Version+1
    if @configuration["company"]["bitbucket_username"] == nil || @configuration["company"]["bitbucket_password"] == nil
      catapult_exception("Please set [\"company\"][\"bitbucket_username\"] and [\"company\"][\"bitbucket_password\"] in secrets/configuration.yml")
    else
      uri = URI("https://api.bitbucket.org/1.0/user/repositories")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The Bitbucket API could not authenticate, please verify [\"company\"][\"bitbucket_username\"] and [\"company\"][\"bitbucket_password\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * Bitbucket API authenticated successfully."
          @api_bitbucket = JSON.parse(response.body)
          # verify bitbucket user's catapult ssh key
          uri = URI("https://api.bitbucket.org/1.0/users/#{@configuration["company"]["bitbucket_username"]}/ssh-keys")
          Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new uri.request_uri
            request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
            response = http.request request # Net::HTTPResponse object
            @api_bitbucket_ssh_keys = JSON.parse(response.body)
            @api_bitbucket_ssh_keys_title = false
            @api_bitbucket_ssh_keys_key = false
            unless response.code.to_f.between?(399,600)
              @api_bitbucket_ssh_keys.each do |key|
                if key["label"] == "Catapult"
                  @api_bitbucket_ssh_keys_title = true
                  if "#{key["key"].match(/(\w*-\w*\s\S*)/)}" == "#{File.read("secrets/id_rsa.pub").match(/(\w*-\w*\s\S*)/)}"
                    @api_bitbucket_ssh_keys_key = true
                  end
                end
              end
            end
            unless @api_bitbucket_ssh_keys_title
              catapult_exception("Could not find the SSH Key named \"Catapult\" for your Bitbucket user #{@configuration["company"]["bitbucket_username"]}, please follow Provision Websites at https://github.com/devopsgroup-io/catapult#provision-websites")
            else
              puts "   - Found the ssh public key \"Catapult\" for your Bitbucket user #{@configuration["company"]["bitbucket_username"]}"
            end
            unless @api_bitbucket_ssh_keys_key
              catapult_exception("The SSH Key named \"Catapult\" in Bitbucket does not match your Catapult instance's SSH Key at \"secrets/id_rsa.pub\", please follow Provision Websites at https://github.com/devopsgroup-io/catapult#provision-websites")
            else
              puts "   - The ssh public key \"Catapult\" matches your secrets/id_rsa.pub ssh public key"
            end
          end
        end
      end
    end
    # https://developer.github.com/v3/
    if @configuration["company"]["github_username"] == nil || @configuration["company"]["github_password"] == nil
      catapult_exception("Please set [\"company\"][\"github_username\"] and [\"company\"][\"github_password\"] in secrets/configuration.yml")
    else
      uri = URI("https://api.github.com/user")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth "#{@configuration["company"]["github_username"]}", "#{@configuration["company"]["github_password"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The GitHub API could not authenticate, please verify [\"company\"][\"github_username\"] and [\"company\"][\"github_password\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The GitHub API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * GitHub API authenticated successfully."
          @api_github = JSON.parse(response.body)
          # verify github user's catapult ssh key
          uri = URI("https://api.github.com/user/keys")
          Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new uri.request_uri
            request.basic_auth "#{@configuration["company"]["github_username"]}", "#{@configuration["company"]["github_password"]}"
            response = http.request request # Net::HTTPResponse object
            @api_github_ssh_keys = JSON.parse(response.body)
            @api_github_ssh_keys_title = false
            @api_github_ssh_keys_key = false
            unless response.code.to_f.between?(399,600)
              @api_github_ssh_keys.each do |key|
                if key["title"] == "Catapult"
                  @api_github_ssh_keys_title = true
                  if "#{key["key"].match(/(\w*-\w*\s\S*)/)}" == "#{File.read("secrets/id_rsa.pub").match(/(\w*-\w*\s\S*)/)}"
                    @api_github_ssh_keys_key = true
                  end
                end
              end
            end
            unless @api_github_ssh_keys_title
              catapult_exception("Could not find the SSH Key named \"Catapult\" for your GitHub user #{@configuration["company"]["github_username"]}, please follow Provision Websites at https://github.com/devopsgroup-io/catapult#provision-websites")
            else
              puts "   - Found the ssh public key \"Catapult\" for your GitHub user #{@configuration["company"]["github_username"]}"
            end
            unless @api_github_ssh_keys_key
              catapult_exception("The SSH Key named \"Catapult\" in GitHub does not match your Catapult instance's SSH Key at \"secrets/id_rsa.pub\", please follow Provision Websites at https://github.com/devopsgroup-io/catapult#provision-websites")
            else
              puts "   - The ssh public key \"Catapult\" matches your secrets/id_rsa.pub ssh public key"
            end
          end
        end
      end
    end
    # https://docs.atlassian.com/bamboo/REST/
    if @configuration["company"]["bamboo_base_url"] == nil || @configuration["company"]["bamboo_username"] == nil || @configuration["company"]["bamboo_password"] == nil
      catapult_exception("Please set [\"company\"][\"bamboo_base_url\"] and [\"company\"][\"bamboo_username\"] and [\"company\"][\"bamboo_password\"] in secrets/configuration.yml")
    else
      uri = URI("#{@configuration["company"]["bamboo_base_url"]}rest/api/latest/project.json?os_authType=basic")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth "#{@configuration["company"]["bamboo_username"]}", "#{@configuration["company"]["bamboo_password"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The Bamboo API could not authenticate, please verify [\"company\"][\"bamboo_base_url\"] and [\"company\"][\"bamboo_username\"] and [\"company\"][\"bamboo_password\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The Bamboo API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * Bamboo API authenticated successfully."
          @api_bamboo = JSON.parse(response.body)
          api_bamboo_project_key = @api_bamboo["projects"]["project"].find { |element| element["key"] == "CAT" }
          unless api_bamboo_project_key
            catapult_exception("Could not find the project key \"CAT\" in Bamboo, please follow the Services Setup for Bamboo at https://github.com/devopsgroup-io/catapult#services-setup")
          end
          api_bamboo_project_name = @api_bamboo["projects"]["project"].find { |element| element["name"] == "Catapult" }
          unless api_bamboo_project_name
            catapult_exception("Could not find the project name \"Catapult\" in Bamboo, please follow the Services Setup for Bamboo at https://github.com/devopsgroup-io/catapult#services-setup")
          else
            puts "   - Found the project key \"CAT\""
          end
        end
        uri = URI("#{@configuration["company"]["bamboo_base_url"]}rest/api/latest/result/CAT-TEST.json?os_authType=basic")
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new uri.request_uri
          request.basic_auth "#{@configuration["company"]["bamboo_username"]}", "#{@configuration["company"]["bamboo_password"]}"
          response = http.request request
          if response.code.to_f.between?(399,499)
            catapult_exception("Could not find the plan key \"TEST\" in Bamboo, please follow the Services Setup for Bamboo at https://github.com/devopsgroup-io/catapult#services-setup")
          elsif response.code.to_f.between?(500,600)
            puts "   - The Bamboo API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
          else
            puts "   - Found the plan key \"TEST\""
          end
        end
        uri = URI("#{@configuration["company"]["bamboo_base_url"]}rest/api/latest/result/CAT-QC.json?os_authType=basic")
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new uri.request_uri
          request.basic_auth "#{@configuration["company"]["bamboo_username"]}", "#{@configuration["company"]["bamboo_password"]}"
          response = http.request request
          if response.code.to_f.between?(399,499)
            catapult_exception("Could not find the plan key \"QC\" in Bamboo, please follow the Services Setup for Bamboo at https://github.com/devopsgroup-io/catapult#services-setup")
          elsif response.code.to_f.between?(500,600)
            puts "   - The Bamboo API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
          else
            puts "   - Found the plan key \"QC\""
          end
        end
        uri = URI("#{@configuration["company"]["bamboo_base_url"]}rest/api/latest/result/CAT-PROD.json?os_authType=basic")
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new uri.request_uri
          request.basic_auth "#{@configuration["company"]["bamboo_username"]}", "#{@configuration["company"]["bamboo_password"]}"
          response = http.request request
          if response.code.to_f.between?(399,499)
            catapult_exception("Could not find the plan key \"PROD\" in Bamboo, please follow the Services Setup for Bamboo at https://github.com/devopsgroup-io/catapult#services-setup")
          elsif response.code.to_f.between?(500,600)
            puts "   - The Bamboo API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
          else
            puts "   - Found the plan key \"PROD\""
          end
        end
      end
    end
    # http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
    # http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html
    if @configuration["company"]["aws_access_key"] == nil || @configuration["company"]["aws_secret_key"] == nil
      catapult_exception("Please set [\"company\"][\"aws_access_key\"] and [\"company\"][\"aws_secret_key\"] in secrets/configuration.yml")
    else
      # ************* REQUEST VALUES *************
      method = 'GET'
      service = 'ec2'
      host = 'ec2.amazonaws.com'
      region = 'us-east-1'
      endpoint = 'https://ec2.amazonaws.com'
      request_parameters = 'Action=DescribeRegions&Version=2013-10-15'
      # Key derivation functions. See:
      # http://docs.aws.amazon.com/general/latest/gr/signature-v4-examples.html#signature-v4-examples-python
      def Command::getSignatureKey(key, dateStamp, regionName, serviceName)
          kDate    = OpenSSL::HMAC.digest('sha256', "AWS4" + key, dateStamp)
          kRegion  = OpenSSL::HMAC.digest('sha256', kDate, regionName)
          kService = OpenSSL::HMAC.digest('sha256', kRegion, serviceName)
          kSigning = OpenSSL::HMAC.digest('sha256', kService, "aws4_request")
          return kSigning
      end
      # Create a date for headers and the credential string
      t = Time.now.utc
      amzdate = t.strftime('%Y%m%dT%H%M%SZ')
      datestamp = t.strftime('%Y%m%d') # Date w/o time, used in credential scope
      # ************* TASK 1: CREATE A CANONICAL REQUEST *************
      # http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
      # Step 1 is to define the verb (GET, POST, etc.)--already done.
      # Step 2: Create canonical URI--the part of the URI from domain to query 
      # string (use '/' if no path)
      canonical_uri = '/' 
      # Step 3: Create the canonical query string. In this example (a GET request),
      # request parameters are in the query string. Query string values must
      # be URL-encoded (space=%20). The parameters must be sorted by name.
      # For this example, the query string is pre-formatted in the request_parameters variable.
      canonical_querystring = request_parameters
      # Step 4: Create the canonical headers and signed headers. Header names
      # and value must be trimmed and lowercase, and sorted in ASCII order.
      # Note that there is a trailing \n.
      canonical_headers = 'host:' + host + "\n" + 'x-amz-date:' + amzdate + "\n"
      # Step 5: Create the list of signed headers. This lists the headers
      # in the canonical_headers list, delimited with ";" and in alpha order.
      # Note: The request can include any headers; canonical_headers and
      # signed_headers lists those that you want to be included in the 
      # hash of the request. "Host" and "x-amz-date" are always required.
      signed_headers = 'host;x-amz-date'
      # Step 6: Create payload hash (hash of the request body content). For GET
      # requests, the payload is an empty string ("").
      payload_hash = Digest::SHA256.hexdigest('')
      # Step 7: Combine elements to create create canonical request
      canonical_request = method + "\n" + canonical_uri + "\n" + canonical_querystring + "\n" + canonical_headers + "\n" + signed_headers + "\n" + payload_hash
      # ************* TASK 2: CREATE THE STRING TO SIGN*************
      # Match the algorithm to the hashing algorithm you use, either SHA-1 or
      # SHA-256 (recommended)
      algorithm = 'AWS4-HMAC-SHA256'
      credential_scope = datestamp + '/' + region + '/' + service + '/' + 'aws4_request'
      string_to_sign = algorithm + "\n" +  amzdate + "\n" +  credential_scope + "\n" + Digest::SHA256.hexdigest(canonical_request)
      # ************* TASK 3: CALCULATE THE SIGNATURE *************
      # Create the signing key using the function defined above.
      signing_key = getSignatureKey(@configuration["company"]["aws_secret_key"], datestamp, region, service)
      # Sign the string_to_sign using the signing_key
      signature = OpenSSL::HMAC.hexdigest('sha256', signing_key, string_to_sign)
      # ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
      # The signing information can be either in a query string value or in 
      # a header named Authorization. This code shows how to use a header.
      # Create authorization header and add to request headers
      authorization_header = algorithm + ' ' + 'Credential=' + @configuration["company"]["aws_access_key"] + '/' + credential_scope + ', ' +  'SignedHeaders=' + signed_headers + ', ' + 'Signature=' + signature
      # ************* SEND THE REQUEST *************
      uri = URI(endpoint + '?' + canonical_querystring)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field "Authorization", "#{authorization_header}"
        request.add_field "x-amz-date", "#{amzdate}"
        request.add_field "content-type", "application/json" #@todo this doesn't seem to work
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The AWS API could not authenticate, please verify [\"company\"][\"aws_access_key\"] and [\"company\"][\"aws_secret_key\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The AWS API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * AWS API authenticated successfully."
        end
      end

    end
    # https://api.cloudflare.com/
    if @configuration["company"]["cloudflare_api_key"] == nil || @configuration["company"]["cloudflare_email"] == nil
      catapult_exception("Please set [\"company\"][\"cloudflare_api_key\"] and [\"company\"][\"cloudflare_email\"] in secrets/configuration.yml")
    else
      uri = URI("https://api.cloudflare.com/client/v4/zones")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field "X-Auth-Key", "#{@configuration["company"]["cloudflare_api_key"]}"
        request.add_field "X-Auth-Email", "#{@configuration["company"]["cloudflare_email"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The CloudFlare API could not authenticate, please verify [\"company\"][\"cloudflare_api_key\"] and [\"company\"][\"cloudflare_email\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The CloudFlare API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * CloudFlare API authenticated successfully."
          @api_cloudflare = JSON.parse(response.body)
        end
      end
    end
    # https://docs.newrelic.com/docs/apis/rest-api-v2
    if @configuration["company"]["newrelic_api_key"] == nil || @configuration["company"]["newrelic_license_key"] == nil
      catapult_exception("Please set [\"company\"][\"newrelic_api_key\"] and [\"company\"][\"newrelic_license_key\"] in secrets/configuration.yml")
    else
      uri = URI("https://api.newrelic.com/v2/users.json")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field "X-Api-Key", "#{@configuration["company"]["newrelic_api_key"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The New Relic API could not authenticate, please verify [\"company\"][\"newrelic_api_key\"] and [\"company\"][\"newrelic_license_key\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The New Relic API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * New Relic API authenticated successfully."
          @api_cloudflare = JSON.parse(response.body)
        end
      end
    end
    # https://docs.newrelic.com/docs/apis
    if @configuration["company"]["newrelic_admin_api_key"] == nil
      catapult_exception("Please set [\"company\"][\"newrelic_admin_api_key\"] in secrets/configuration.yml")
    else
      uri = URI("https://synthetics.newrelic.com/synthetics/api/v1/monitors")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field "X-Api-Key", "#{@configuration["company"]["newrelic_admin_api_key"]}"
        response = http.request request
        if response.code.to_f.between?(399,499)
          catapult_exception("The New Relic Admin API could not authenticate, please verify [\"company\"][\"newrelic_admin_api_key\"].")
        elsif response.code.to_f.between?(500,600)
          puts "   - The New Relic Admin API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
        else
          puts " * New Relic Admin API authenticated successfully."
          @api_cloudflare = JSON.parse(response.body)
        end
      end
    end
    puts "\nVerification of configuration[\"environments\"]:\n".color(Colors::WHITE)
    puts "[redhat]"
    # get full list of available digitalocean slugs to validate against
    uri = URI("https://api.digitalocean.com/v2/sizes")
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request.add_field "Authorization", "Bearer #{@configuration["company"]["digitalocean_personal_access_token"]}"
      response = http.request request
      if response.code.to_f.between?(399,499)
        catapult_exception("The DigitalOcean API could not authenticate, please verify [\"company\"][\"digitalocean_personal_access_token\"].")
      elsif response.code.to_f.between?(500,600)
        puts "   - The DigitalOcean API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
      else
        api_digitalocean_sizes = JSON.parse(response.body)
        @api_digitalocean_slugs = Array.new
        api_digitalocean_sizes["sizes"].each do |size|
          @api_digitalocean_slugs.push("#{size["slug"]}")
        end
      end
    end
    # validate @configuration["environments"]
    @configuration["environments"].each do |environment,data|
      #validate digitalocean droplets
      unless "#{environment}" == "dev" || @api_digitalocean == nil

        # redhat droplet
        droplet = @api_digitalocean["droplets"].find { |element| element['name'] == "#{@configuration["company"]["name"].downcase}-#{environment}-redhat" }
        # if redhat digitalocean droplet has been created
        if droplet != nil
          droplet_ip = droplet["networks"]["v4"].find { |element| element["type"] == "public" }
          droplet_ip_private = droplet["networks"]["v4"].find { |element| element["type"] == "private" }
          puts " * DigitalOcean droplet #{@configuration["company"]["name"].downcase}-#{environment}-redhat has been found."
          puts "   - [status] #{droplet["status"]} [memory] #{droplet["size"]["memory"]} [vcpus] #{droplet["size"]["vcpus"]} [disk] #{droplet["size"]["disk"]} [$/month] $#{droplet["size"]["price_monthly"]}"
          puts "   - [created] #{droplet["created_at"]} [slug] #{droplet["size"]["slug"]} [region] #{droplet["region"]["name"]} [kernel] #{droplet["kernel"]["name"]}"
          puts "   - [ipv4_public] #{droplet_ip["ip_address"]} [ipv4_private] #{droplet_ip_private["ip_address"]}"
          # get public ip address and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip"] == droplet_ip["ip_address"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip"] = "#{droplet_ip["ip_address"]}"
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
          # get private ip address and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip_private"] == droplet_ip_private["ip_address"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat"]["ip_private"] = "#{droplet_ip_private["ip_address"]}"
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
          # get slug and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat"]["slug"] == droplet["size"]["slug"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat"]["slug"] = droplet["size"]["slug"]
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
        # if redhat digitalocean droplet has NOT been created
        elsif @configuration["environments"]["#{environment}"]["servers"]["redhat"]["slug"] == nil
          catapult_exception("There is an error in your secrets/configuration.yml file.\nThe slug (DigitalOcean droplet size) for #{environment} => servers => redhat is empty and the droplet has not been created. Please choose from the following (see DigitalOcean.com for pricing):\n#{@api_digitalocean_slugs}")
        elsif not @api_digitalocean_slugs.include?("#{@configuration["environments"]["#{environment}"]["servers"]["redhat"]["slug"]}")
          catapult_exception("There is an error in your secrets/configuration.yml file.\nThe slug (DigitalOcean droplet size) for #{environment} => servers => redhat is invalid and the droplet has not been created. Please choose from the following (see DigitalOcean.com for pricing):\n#{@api_digitalocean_slugs}")
        else
          puts " * DigitalOcean droplet #{@configuration["company"]["name"].downcase}-#{environment}-redhat has not been created, please vagrant up #{@configuration["company"]["name"].downcase}-#{environment}-redhat"
        end

        # redhat_mysql droplet
        droplet = @api_digitalocean["droplets"].find { |element| element['name'] == "#{@configuration["company"]["name"].downcase}-#{environment}-redhat-mysql" }
        # if redhat_mysql digitalocean droplet has been created
        if droplet != nil
          droplet_ip = droplet["networks"]["v4"].find { |element| element["type"] == "public" }
          droplet_ip_private = droplet["networks"]["v4"].find { |element| element["type"] == "private" }
          puts " * DigitalOcean droplet #{@configuration["company"]["name"].downcase}-#{environment}-redhat_mysql has been found."
          puts "   - [status] #{droplet["status"]} [memory] #{droplet["size"]["memory"]} [vcpus] #{droplet["size"]["vcpus"]} [disk] #{droplet["size"]["disk"]} [$/month] $#{droplet["size"]["price_monthly"]}"
          puts "   - [created] #{droplet["created_at"]} [slug] #{droplet["size"]["slug"]} [region] #{droplet["region"]["name"]} [kernel] #{droplet["kernel"]["name"]}"
          puts "   - [ipv4_public] #{droplet_ip["ip_address"]} [ipv4_private] #{droplet_ip_private["ip_address"]}"
          # get public ip address and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip"] == droplet_ip["ip_address"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip"] = "#{droplet_ip["ip_address"]}"
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
          # get private ip address and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip_private"] == droplet_ip_private["ip_address"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["ip_private"] = "#{droplet_ip_private["ip_address"]}"
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
          # get slug and write to secrets/configuration.yml
          unless @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["slug"] == droplet["size"]["slug"]
            @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["slug"] = droplet["size"]["slug"]
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
            File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
            `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
          end
        # if redhat_mysql digitalocean droplet has NOT been created
        elsif @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["slug"] == nil
          catapult_exception("There is an error in your secrets/configuration.yml file.\nThe slug (DigitalOcean droplet size) for #{environment} => servers => redhat_mysql is empty and the droplet has not been created. Please choose from the following (see DigitalOcean.com for pricing):\n#{@api_digitalocean_slugs}")
        elsif not @api_digitalocean_slugs.include?("#{@configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["slug"]}")
          catapult_exception("There is an error in your secrets/configuration.yml file.\nThe slug (DigitalOcean droplet size) for #{environment} => servers => redhat_mysql is invalid and the droplet has not been created. Please choose from the following (see DigitalOcean.com for pricing):\n#{@api_digitalocean_slugs}")
        else
          puts " * DigitalOcean droplet #{@configuration["company"]["name"].downcase}-#{environment}-redhat_mysql has not been created, please vagrant up #{@configuration["company"]["name"].downcase}-#{environment}-redhat_mysql"
        end
      
      end
      # if server passwords do not exist, create them
      unless @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["user_password"]
        @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["user_password"] = SecureRandom.urlsafe_base64(16)
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
        File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
      end
      unless @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["root_password"]
        @configuration["environments"]["#{environment}"]["servers"]["redhat_mysql"]["mysql"]["root_password"] = SecureRandom.urlsafe_base64(16)
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
        File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
      end
      unless @configuration["environments"]["#{environment}"]["software"]["drupal"]["admin_password"]
        @configuration["environments"]["#{environment}"]["software"]["drupal"]["admin_password"] = SecureRandom.urlsafe_base64(16)
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
        File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
      end
      unless @configuration["environments"]["#{environment}"]["software"]["wordpress"]["admin_password"]
        @configuration["environments"]["#{environment}"]["software"]["wordpress"]["admin_password"] = SecureRandom.urlsafe_base64(16)
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml --decrypt secrets/configuration.yml.gpg`
        File.open('secrets/configuration.yml', 'w') {|f| f.write configuration.to_yaml }
        `gpg --verbose --batch --yes --passphrase "#{@configuration_user["settings"]["gpg_key"]}" --output secrets/configuration.yml.gpg --armor --cipher-algo AES256 --symmetric secrets/configuration.yml`
      end
    end
    puts "\nVerification of configuration[\"websites\"]:\n".color(Colors::WHITE)
    # add catapult temporarily to verify repo and add bamboo services
    @configuration["websites"]["catapult"] = *(["domain" => "#{@repo}", "repo" => "#{@repo}"])
    # validate @configuration["websites"]
    @configuration["websites"].each do |service,data|
      if "#{service}" == "catapult"
        puts "\nVerification of this Catapult instance:\n".color(Colors::WHITE)
      end
      # create array of domains to later validate domain alpha order per service
      domains = Array.new
      domains_sorted = Array.new
      unless @configuration["websites"]["#{service}"] == nil
        puts " [#{service}]"
        @configuration["websites"]["#{service}"].each do |instance|
          puts " * #{instance["domain"]}"
          unless "#{service}" == "catapult"
            # validate the domain to ensure it only includes the domain and not protocol
            if instance["domain"].include? "://"
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe domain for websites => #{service} => domain => #{instance["domain"]} is invalid, it must not include http:// or https://")
            end
            # validate the domain depth
            domain_depth = instance["domain"].split(".")
            if domain_depth.count > 3
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe domain for websites => #{service} => domain => #{instance["domain"]} is invalid, there is a maximum of one subdomain")
            end
            # validate the domain_tld_overrided depth
            unless instance["domain_tld_override"] == nil
              domain_tld_override_depth = instance["domain_tld_override"].split(".")
              if domain_tld_override_depth.count != 2
                catapult_exception("There is an error in your secrets/configuration.yml file.\nThe domain_tld_override for websites => #{service} => domain => #{instance["domain"]} is invalid, it must only be one domain level (company.com)")
              end
            end
          end
          # validate force_auth_exclude
          unless instance["force_auth_exclude"] == nil
            @force_auth_exclude_valid_values = true
            instance["force_auth_exclude"].each do |value|
              if not ["test","qc","production"].include?("#{value}")
                @force_auth_exclude_valid_values = false
              end
            end
            unless @force_auth_exclude_valid_values
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe force_auth_exclude for websites => #{service} => domain => #{instance["domain"]} is invalid, it must only include one, some, or all of the following [\"test\",\"qc\",\"production\"].")
            end
          end
          # validate force_https
          unless instance["force_https"] == nil
            unless ["true"].include?("#{instance["force_https"]}")
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe force_https for websites => #{service} => domain => #{instance["domain"]} is invalid, it must be true or removed.")
            end
            unless instance["domain_tld_override"] == nil
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe force_https for websites => #{service} => domain => #{instance["domain"]} cannot be used in conjuction with domain_tld_override.")
            end
          end
          # create array of domains to later validate repo alpha order per service
          domains.push("#{instance["domain"]}")
          domains_sorted.push("#{instance["domain"]}")
          # validate repo uri
          if instance["repo"].include? "git@"
            # instance["repo"] => git@github.com:devopsgroup-io/devopsgroup-io(.git)
            repo_split_1 = instance["repo"].split("@")
            # repo_split_1[0] => git
            # repo_split_1[1] => github.com:devopsgroup-io/devopsgroup-io(.git)
            repo_split_2 = repo_split_1[1].split(":")
            # repo_split_2[0] => github.com
            # repo_split_2[1] => devopsgroup-io/devopsgroup-io(.git)
            repo_split_3 = repo_split_2[1].split(".git")
            # repo_split_3[0] => devopsgroup-io/devopsgroup-io
            # if there is a .git on the end, repo_split_3[0] will have a value, otherwise set equal to repo_split_2[1]
            if repo_split_3[0]
              repo_split_2[1] = repo_split_3[0]
            end
          else
            # instance["repo"] => https://github.com/seth-reeser/catapult(.git)
            repo_split_1 = instance["repo"].split("://")
            # repo_split_1[0] => https
            # repo_split_1[1] => github.com/seth-reeser/catapult(.git)
            repo_split_2 = repo_split_1[1].split("/", 2)
            # repo_split_2[0] => github.com
            # repo_split_2[1] => seth-reeser/catapult(.git)
            repo_split_3 = repo_split_2[1].split(".git")
            # repo_split_3[0] => devopsgroup-io/devopsgroup-io
            # if there is a .git on the end, repo_split_3[0] will have a value, otherwise set equal to repo_split_2[1]
            if repo_split_3[0]
              repo_split_2[1] = repo_split_3[0]
            end
          end
          unless "#{service}" == "catapult"
            # validate repo is an ssh uri
            unless "#{repo_split_1[0]}" == "git"
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe repo for websites => #{service} => domain => #{instance["domain"]} is invalid, the format must be git@github.com:devopsgroup-io/devopsgroup-io.git")
            end
            # validate repo hosted at bitbucket.org or github.com
            unless "#{repo_split_2[0]}" == "bitbucket.org" || "#{repo_split_2[0]}" == "github.com"
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe repo for websites => #{service} => domain => #{instance["domain"]} is invalid, it must either be a bitbucket.org or github.com repository.")
            end
          end
          # validate access to repo
          if "#{repo_split_2[0]}" == "bitbucket.org"
            @api_bitbucket_repo_access = false
            uri = URI("https://api.bitbucket.org/2.0/repositories/#{repo_split_3[0]}")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f == 404
                catapult_exception("The Bitbucket repo #{instance["repo"]} does not exist")
              elsif response.code.to_f.between?(399,600)
                puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_bitbucket_repo_repositories = JSON.parse(response.body)
                if response.code.to_f == 200
                  if api_bitbucket_repo_repositories["owner"]["username"] == "#{@configuration["company"]["bitbucket_username"]}"
                    @api_bitbucket_repo_access = true
                  end
                end
              end
            end
            uri = URI("https://api.bitbucket.org/1.0/privileges/#{repo_split_3[0]}")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f == 404
                catapult_exception("The Bitbucket repo #{instance["repo"]} does not exist")
              elsif response.code.to_f.between?(399,600)
                puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_bitbucket_repo_privileges = JSON.parse(response.body)
                api_bitbucket_repo_privileges.each do |member|
                  if member["privilege"] == "admin" || member["privilege"] == "write"
                    if member["user"]["username"] == "#{@configuration["company"]["bitbucket_username"]}"
                      @api_bitbucket_repo_access = true
                    end
                  end
                end
              end
            end
            uri = URI("https://api.bitbucket.org/1.0/group-privileges/#{repo_split_3[0]}")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f == 404
                catapult_exception("The Bitbucket repo #{instance["repo"]} does not exist")
              elsif response.code.to_f.between?(399,600)
                puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_bitbucket_repo_group_privileges = JSON.parse(response.body)
                api_bitbucket_repo_group_privileges.each do |group|
                  if group["privilege"] == "admin" || group["privilege"] == "write"
                    group["group"]["members"].each do |member|
                      if member["username"] == "#{@configuration["company"]["bitbucket_username"]}"
                        @api_bitbucket_repo_access = true
                      end
                    end
                  end
                end
              end
            end
            if @api_bitbucket_repo_access === false
              catapult_exception("Your Bitbucket user #{@configuration["company"]["bitbucket_username"]} does not have write access to this repository.")
            elsif @api_bitbucket_repo_access === true
              puts "   - Verified your Bitbucket user #{@configuration["company"]["bitbucket_username"]} has write access."
            end
          end
          if "#{repo_split_2[0]}" == "github.com"
            uri = URI("https://api.github.com/repos/#{repo_split_3[0]}/collaborators/#{@configuration["company"]["github_username"]}")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["github_username"]}", "#{@configuration["company"]["github_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f == 404
                catapult_exception("The GitHub repo #{instance["repo"]} does not exist")
              elsif response.code.to_f.between?(399,600)
                puts "   - The GitHub API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                if response.code.to_f == 204
                  puts "   - Verified your GitHub user #{@configuration["company"]["github_username"]} has write access."
                else
                  catapult_exception("Your GitHub user #{@configuration["company"]["github_username"]} does not have write access to this repository.")
                end
              end
            end
          end
          # validate repo branches
          if "#{repo_split_2[0]}" == "bitbucket.org"
            uri = URI("https://api.bitbucket.org/1.0/repositories/#{repo_split_3[0]}/branches")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f.between?(399,600)
                puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_bitbucket_repo_branches = JSON.parse(response.body)
                @api_bitbucket_repo_develop = false
                @api_bitbucket_repo_release = false
                @api_bitbucket_repo_master = false
                api_bitbucket_repo_branches.each do |branch, array|
                  if branch == "develop"
                    @api_bitbucket_repo_develop = true
                  end
                  if branch == "release"
                    @api_bitbucket_repo_release = true
                  end
                  if branch == "master"
                    @api_bitbucket_repo_master = true
                  end
                end
                unless @api_bitbucket_repo_develop
                  catapult_exception("Cannot find the develop branch for this repository, please create one.")
                else
                  puts "   - Found the develop branch."
                end
                unless @api_bitbucket_repo_release
                  catapult_exception("Cannot find the release branch for this repository, please create one.")
                else
                  puts "   - Found the release branch."
                end
                unless @api_bitbucket_repo_master
                  catapult_exception("Cannot find the master branch for this repository, please create one.")
                else
                  puts "   - Found the master branch."
                end
              end
            end
          end
          if "#{repo_split_2[0]}" == "github.com"
            uri = URI("https://api.github.com/repos/#{repo_split_3[0]}/branches")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["github_username"]}", "#{@configuration["company"]["github_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f.between?(399,600)
                puts "   - The GitHub API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_github_repo_branches = JSON.parse(response.body)
                @api_github_repo_develop = false
                @api_github_repo_release = false
                @api_github_repo_master = false
                api_github_repo_branches.each do |branch|
                  if branch["name"] == "develop"
                    @api_github_repo_develop = true
                  end
                  if branch["name"] == "release"
                    @api_github_repo_release = true
                  end
                  if branch["name"] == "master"
                    @api_github_repo_master = true
                  end
                end
                unless @api_github_repo_develop
                  catapult_exception("Cannot find the develop branch for this repository, please create one.")
                else
                  puts "   - Found the develop branch."
                end
                unless @api_github_repo_release
                  catapult_exception("Cannot find the release branch for this repository, please create one.")
                else
                  puts "   - Found the release branch."
                end
                unless @api_github_repo_master
                  catapult_exception("Cannot find the master branch for this repository, please create one.")
                else
                  puts "   - Found the master branch."
                end
              end
            end
          end
          # create bamboo service per bitbucket repo
          if "#{repo_split_2[0]}" == "bitbucket.org"
            # the bitbucket api offers no patch for service hooks, so we first need to check if the bitbucket bamboo service hooks exist
            uri = URI("https://api.bitbucket.org/1.0/repositories/#{repo_split_3[0]}/services")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f.between?(399,600)
                puts "   - The Bitbucket API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              else
                api_bitbucket_services = JSON.parse(response.body)
                @api_bitbucket_services_bamboo_cat_test = false
                @api_bitbucket_services_bamboo_cat_qc = false
                api_bitbucket_services.each do |service|
                  if service["service"]["type"] == "Bamboo"
                    service["service"]["fields"].each do |field|
                      if field["name"] == "Plan Key"
                        if field["value"] == "CAT-TEST"
                          @api_bitbucket_services_bamboo_cat_test = true
                        end
                        if field["value"] == "CAT-QC"
                          @api_bitbucket_services_bamboo_cat_qc = true
                        end
                      end
                    end
                  end
                end
                unless @api_bitbucket_services_bamboo_cat_test
                  uri = URI("https://api.bitbucket.org/1.0/repositories/#{repo_split_3[0]}/services")
                  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                    request = Net::HTTP::Post.new uri.request_uri
                    request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
                    request.body = URI::encode\
                      (""\
                        "type=Bamboo"\
                        "&URL=#{@configuration["company"]["bamboo_base_url"]}"\
                        "&Plan Key=CAT-TEST"\
                        "&Username=#{@configuration["company"]["bamboo_username"]}"\
                        "&Password=#{@configuration["company"]["bamboo_password"]}"\
                      "")
                    response = http.request request # Net::HTTPResponse object
                    if response.code.to_f.between?(399,600)
                      catapult_exception("Unable to configure Bitbucket Bamboo service for websites => #{service} => domain => #{instance["domain"]}. Ensure the github_username defined in secrets/configuration.yml has correct access to the repository.")
                    end
                  end
                end
                unless @api_bitbucket_services_bamboo_cat_qc
                  uri = URI("https://api.bitbucket.org/1.0/repositories/#{repo_split_3[0]}/services")
                  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                    request = Net::HTTP::Post.new uri.request_uri
                    request.basic_auth "#{@configuration["company"]["bitbucket_username"]}", "#{@configuration["company"]["bitbucket_password"]}"
                    request.body = URI::encode\
                      (""\
                        "type=Bamboo"\
                        "&URL=#{@configuration["company"]["bamboo_base_url"]}"\
                        "&Plan Key=CAT-QC"\
                        "&Username=#{@configuration["company"]["bamboo_username"]}"\
                        "&Password=#{@configuration["company"]["bamboo_password"]}"\
                      "")
                    response = http.request request # Net::HTTPResponse object
                    if response.code.to_f.between?(399,600)
                      catapult_exception("Unable to configure Bitbucket Bamboo service for websites => #{service} => domain => #{instance["domain"]}. Ensure the github_username defined in secrets/configuration.yml has correct access to the repository.")
                    end
                  end
                end
              end
            end
          end
          # create bamboo service per github repo
          if "#{repo_split_2[0]}" == "github.com"
            uri = URI("https://api.github.com/repos/#{repo_split_3[0]}/hooks")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Post.new uri.request_uri
              request.basic_auth "#{@configuration["company"]["github_username"]}", "#{@configuration["company"]["github_password"]}"
              request.body = ""\
                "{"\
                  "\"name\":\"bamboo\","\
                  "\"active\":true,"\
                  "\"config\":"\
                    "{"\
                      "\"base_url\":\"#{@configuration["company"]["bamboo_base_url"]}\","\
                      "\"build_key\":\"develop:CAT-TEST,release:CAT-QC\","\
                      "\"username\":\"#{@configuration["company"]["bamboo_username"]}\","\
                      "\"password\":\"#{@configuration["company"]["bamboo_password"]}\""\
                    "}"\
                "}"
              response = http.request request # Net::HTTPResponse object
              if response.code.to_f.between?(500,600)
                puts "   - The GitHub API seems to be down, skipping... (this may impact provisioning and automated deployments)".color(Colors::RED)
              elsif response.code.to_f.between?(399,499)
                catapult_exception("Unable to configure GitHub Bamboo service for websites => #{service} => domain => #{instance["domain"]}. Ensure the github_username defined in secrets/configuration.yml has correct access to the repository.")
              end
            end
          end
          puts "   - Configured Bamboo service for automated deployments."
          # validate software
          unless instance["software"] == nil
            # create an array of available software
            provisioners_software = Array.new
            unless @provisioners["software"]["#{service}"] == nil
              @provisioners["software"]["#{service}"].each { |i, v| provisioners_software.push(i) }
            end
            unless provisioners_software.include?("#{instance["software"]}")
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe software for websites => #{service} => domain => #{instance["domain"]} is invalid, it must be one of the following #{provisioners_software.join(", ")}.")
            end
            unless ["downstream","upstream"].include?("#{instance["software_workflow"]}")
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe software for websites => #{service} => domain => #{instance["domain"]} requires the software_workflow option, it must be one of the following [\"downstream\",\"upstream\"].")
            end
          end
          # validate webroot
          unless instance["webroot"] == nil
            unless "#{instance["webroot"]}"[-1,1] == "/"
              catapult_exception("There is an error in your secrets/configuration.yml file.\nThe webroot for websites => #{service} => domain => #{instance["domain"]} is invalid, it must include a trailing slash.")
            end
          end
        end
      end
      # ensure domains are in alpha order
      domains_sorted = domains_sorted.sort
      if domains != domains_sorted
        catapult_exception("There is an error in your secrets/configuration.yml file.\nThe domains in secrets/configuration.yml are not in alpha order for websites => #{service} - please adjust.")
      end
    end
    # remove catapult as this was done to temporarily verify repo and add bamboo services
    @configuration["websites"].delete("catapult")


    # create arrays of domains for localdev hosts file
    @dev_redhat_hosts = Array.new
    unless @configuration["websites"]["apache"] == nil
      @configuration["websites"]["apache"].each do |instance|
        if instance["domain_tld_override"] == nil
          @dev_redhat_hosts.push("dev.#{instance["domain"]}")
          @dev_redhat_hosts.push("www.dev.#{instance["domain"]}")
        else
          @dev_redhat_hosts.push("dev.#{instance["domain"]}.#{instance["domain_tld_override"]}")
          @dev_redhat_hosts.push("www.dev.#{instance["domain"]}.#{instance["domain_tld_override"]}")
        end
      end
    end
    @dev_windows_hosts = Array.new
      unless @configuration["websites"]["iis"] == nil
      @configuration["websites"]["iis"].each do |instance|
        @dev_windows_hosts.push("dev.#{instance["domain"]}")
        @dev_windows_hosts.push("www.dev.#{instance["domain"]}")
      end
    end


    # remove lock file
    File.delete('.lock')


    # vagrant status binding
    if ["status"].include?(ARGV[0])
      totalwebsites = 0
      # start a new row
      puts "\n\n\nAvailable websites legend:".color(Colors::WHITE)
      puts "\n[http response codes]"
      puts " * The below http response codes are started from http:// and up to 10 redirects allowed - so if you're forcing https://, you will end up with that code below."
      puts " * 200 ok, 301 moved permanently, 302 found, 400 bad request, 401 unauthorized, 403 forbidden, 404 not found, 500 internal server error, 502 bad gateway, 503 service unavailable, 504 gateway timeout"
      puts " * http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html"
      puts " * Keep in mind these response codes and nslookups are from within your network - they may differ externally if you're running your own DNS server internally."
      puts "\nAvailable websites:".color(Colors::WHITE)
      puts "".ljust(42) + "[software]".ljust(14) + "[workflow]".ljust(14) + "[80:dev.]".ljust(21) + "[80:test.]".ljust(21) + "[80:qc.]".ljust(21) + "[80:production]"

      @configuration["websites"].each do |service,data|
        if @configuration["websites"]["#{service}"] == nil
          puts "\n[#{service}]"
          puts " * none"
        else
          puts "\n[#{service}]"
          @configuration["websites"]["#{service}"].each do |instance|
            # count websites
            totalwebsites = totalwebsites + 1
            # start new row
            row = Array.new
            # get domain name
            if instance["domain_tld_override"] == nil
              row.push(" * #{instance["domain"]}".ljust(41))
            else
              row.push(" * #{instance["domain"]}.#{instance["domain_tld_override"]}".ljust(41))
            end
            # get software
            row.push((instance["software"] || "").ljust(13))
            # get software workflow
            row.push((instance["software_workflow"] || "").ljust(13))
            # get http response code per environment
            @configuration["environments"].each do |environment,data|
              response = nil
              if ["production"].include?("#{environment}")
                environment = nil
              else
                environment = "#{environment}."
              end
              begin
                def Command::http_repsonse(uri_str, limit = 10)
                  if limit == 0
                    row.push("loop")
                  else
                    response = Net::HTTP.get_response(URI(uri_str))
                    case response
                    when Net::HTTPSuccess then
                      if response.code.to_f.between?(200,399)
                        return response.code.ljust(4).color(Colors::GREEN)
                      elsif response.code.to_f.between?(400,499)
                        return response.code.ljust(4).color(Colors::YELLOW)
                      elsif response.code.to_f.between?(500,599)
                        return response.code.ljust(4).color(Colors::RED)
                      end
                    when Net::HTTPRedirection then
                      location = response['location']
                      http_repsonse(location, limit - 1)
                    else
                      if response.code.to_f.between?(200,399)
                        return response.code.ljust(4).color(Colors::GREEN)
                      elsif response.code.to_f.between?(400,499)
                        return response.code.ljust(4).color(Colors::YELLOW)
                      elsif response.code.to_f.between?(500,599)
                        return response.code.ljust(4).color(Colors::RED)
                      end
                    end
                  end
                end
                if instance["domain_tld_override"] == nil
                  row.push(http_repsonse("http://#{environment}#{instance["domain"]}"))
                else
                  row.push(http_repsonse("http://#{environment}#{instance["domain"]}.#{instance["domain_tld_override"]}"))
                end
              rescue SocketError
                row.push("down".ljust(4).color(Colors::RED))
              rescue Errno::ECONNREFUSED
                row.push("down".ljust(4).color(Colors::RED))
              rescue EOFError
                row.push("down".ljust(4).color(Colors::RED))
              rescue Net::ReadTimeout
                row.push("down".ljust(4).color(Colors::RED))
              rescue OpenSSL::SSL::SSLError
                row.push("err".ljust(4).color(Colors::RED))
              rescue Exception => ex
                row.push("#{ex.class}".slice!(0, 4).ljust(4).color(Colors::RED))
              end
              # nslookup production top-level domain
              begin
                if instance["domain_tld_override"] == nil
                  row.push((Resolv.getaddress "#{environment}#{instance["domain"]}").ljust(16))
                else
                  row.push((Resolv.getaddress "#{environment}#{instance["domain"]}.#{instance["domain_tld_override"]}").ljust(16))
                end
              rescue
                row.push("down".ljust(16).color(Colors::RED))
              end
            end
            puts row.join(" ")
          end
        end
      end
      # start a new row
      row = Array.new
      puts "\n[total]"
      row.push(" #{totalwebsites}")
      puts row.join(" ")
    end


    puts "\n\n\n"


  end
end
