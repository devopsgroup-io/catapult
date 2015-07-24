# Catapult Release Management #



**Welcome to devopsgroup.io Catapult Release Management**, a complete DevOps Release Management solution featuring automated website deployment and continuous integration following Gitflow and SCRUM workflows. Built for Developers, simple enough to use by non-Developers.

As a non-Developer you may think - *I already have a website, why do I need Catapult?* Over time you will find yourself or find yourself paying a freelancer or a development company hundreds or even thousands of dollars to manage or interact with the DevOps (Development Operations) and solve these problems:

  * *Production is down.*
  * *We need a test site.*
  * *Why is this costing so much?*
  * *Is my website safe?* 
  * *Is my website backed up?*
  * *Can I easily scale my website for more traffic?*

As a Developer, you've probably had to manage many websites and probably end up using the same tools and APIs over and over again. Why not use something that has been developed just for you from Developers that have been down the same road as you and also have the ability to contribute back?

  * Catapult is developed in Ruby and native Shell - no new languages or technologies to learn.
  * Catapult is very simple at its core - there is no black-box to decipher - everything is out in the open.
  * Catapult uses the most popular APIs and services; inlcuding AWS, Bamboo, Bitbucket, CloudFlare, DigitalOcean, GitHub, and Vagrant.

Catapult manages all of this for you and is open-sourced, well-documented, developer-focused, and free to use. We also provide a service if you need some help getting started - if you do, let us know at https://devopsgroup.io. Catapult leverages the Services that you're already using, which collectively, costs $40/month to have a full-stack localDev, Test, Quality Control, and Production environment.

*Go ahead, give* **Catapult** *a* **shot**.

If you're having issues with Catapult, [submit an issue here](https://github.com/devopsgroup-io/catapult-release-management/issues/new).



## Table of Contents ##

- [Catapult Release Management](#catapult-release-management)
    - [Table of Contents](#table-of-contents)
    - [File Structure](#file-structure)
    - [Supported Software](#supported-software)
- [Setup](#setup)
    - [Developer Setup](#developer-setup)
    - [Instance Setup](#instance-setup)
    - [Services Setup](#services-setup)
- [Usage](#usage)
    - [Provision Environments](#provision-environments)
    - [Provision Websites](#provision-websites)
- [Contributing](#contributing)
    - [Versioning](#versioning)



## File Structure ##

```
catapult-release-management/
├── provisioners/
│   ├── .ssh/
│   ├── redhat/
│   │   ├── installers/
│   │   │    └── codeigniter2_database.php
│   │   │    └── drupal6_settings.php
│   │   │    └── drupal7_settings.php
│   │   │    └── wp-cli.phar
│   │   │    └── wp-config.php
│   │   │    └── xenforo_config.php
│   │   │ 
│   │   ├── logs/
│   │   │
│   │   └── provision.sh
│   │
│   ├── redhat_mysql/
│   │   ├── installers/
│   │   ├── logs/
│   │   └── provision.sh
│   │
│   └── windows
│       ├── installers/
│       │    └── poweryaml/
│       │    └── ProcessExplorer/
│       │    └── dotNetFx40_Full_x86_x64.exe
│       │    └── Git-1.9.5-preview20141217.exe
│       │    └── Windows6.1-KB2560289-x64.msu
│       │    
│       ├── logs/
│       └── provision.ps1
│   
├── repositories/
│   ├── apache/
│   └── iis/
│   
├── configuration-user.yml.template
├── configuration.yml.template
└── Vagrantfile
```



## Supported Software ##

Catapult currently supports the following software:

* Any website without a database dependancy built in PHP
* CodeIgniter 2.x
* Drupal 6.x, Drupal 7.x
    * as required by Drush 7.0.0-rc1
* WordPress 3.5.2+, WordPress 4.x
    * as required by WP-CLI



# Setup #

Catapult requires a [Developer Setup](#developer-setup), [Instance Setup](#instance-setup), and [Services Setup](#services-setup) as described in the following sections.

**Please Note:** It is advised to turn off any antivirus software that you may have installed during Developer Setup and Usage of Catapult as necessary tasks such as forwarding ports and writing hosts files may be blocked.



## Developer Setup ##

Catapult is controlled via Vagrant and the command line of a Developer's computer - below is a list of required software.

1. **Vagrant**
    1. Please download and install from https://www.vagrantup.com/downloads.html
2. **VirtualBox**
    1. Please download and install from https://www.virtualbox.org/wiki/Downloads
3. **SourceTree**
    1. Please download and install from https://www.sourcetreeapp.com/
4. **Sublime Text 3**
    1. Please download and install from http://www.sublimetext.com/3
5. **GPG2**
    1. Using OSX ? Please download and install GPG Suite https://gpgtools.org
    2. Using Windows? Please download and install Gpg4win from http://gpg4win.org/download.html



## Instance Setup ##

Catapult is quick to setup. Fork the Github repository and start adding your configuration.

1. **Fork Catapult**
    1. Fork https://github.com/devopsgroup-io/catapult-release-management and clone via SourceTree or the git utility of your choice.
2. **Vagrant Plugins**
    1. Open your command line and cd into the newly cloned repository and install the following Vagrant plugins.
        1. `vagrant plugin install vagrant-digitalocean` [GitHub](https://github.com/smdahlen/vagrant-digitalocean), [RubyGems](https://rubygems.org/gems/vagrant-digitalocean)
        2. `vagrant plugin install vagrant-hostmanager` [GitHub](https://github.com/smdahlen/vagrant-hostmanager), [RubyGems](https://rubygems.org/gems/vagrant-hostmanager)
        3. `vagrant plugin install vagrant-vbguest` [GitHub](https://github.com/dotless-de/vagrant-vbguest), [RubyGems](https://rubygems.org/gems/vagrant-vbguest)
3. **SSH Key Pair**
    1. You will need to create a *passwordless* SSH key pair that will drive authentication for Catapult.
        1. For instructions please see https://help.github.com/articles/generating-ssh-keys/
        2. Place the newly created *passwordless* SSH key pair id_rsa and id_rsa.pub in the ~/provisioners/.ssh/ folder.
4. **GPG Key**
    1. You will need to create your team's gpg_key that will be the single key that encrypts all of your configuration and secrets for your instance.
        1. NEVER SHARE THE KEY WITH ANYONE OTHER THAN YOUR TEAM.
        3. Spaces are not permitted and must be at least 20 characters.
        4. To create a strong key, please visit https://xkpasswd.net/
        5. It is recommended to print a QR code of the key to distribute to your team, please visit http://educastellano.github.io/qr-code/demo/
        6. Remember; security is 99% process and 1% technology.
5. **GPG Edit Mode**
    1. When **GPG Edit Mode** is enabled (disabled by default) the following files are encrypted using your **GPG Key**:
        1. ~/provisioners/.ssh/id_rsa as ~/provisioners/.ssh/id_rsa.gpg
        2. ~/provisioners/.ssh/id_rsa.pub as ~/provisioners/.ssh/id_rsa.pub.gpg
        3. ~/configuration.yml as ~/configuration.yml.gpg
    2. To enable **GPG Edit Mode**, set `~/configuration-user.yml["settings"]["gpg_edit"]` to true.
    3. Once gpg_edit is set to true and while on your fork's master branch, run `vagrant status`, this will encrypt your configuraiton that you will then be able to commit and push safely to your public Catapult fork.



## Services Setup ##

Catapult uses several third-party services to pull everything off - below is a list of the required services and sign-up and configuration steps.

1. **Hosting:** 
    1. **DigitalOcean** sign-up and configuration
        1. Create an account at http://digitalocean.com
        2. Create a Personal Access Token at https://cloud.digitalocean.com/settings/applications named "Vagrant" and place the token value at `~/configuration.yml["company"]["digitalocean_personal_access_token"]`
        3. Add your newly created id_rsa.pub from ~/provisioners/.ssh/id_rsa.pub key in https://cloud.digitalocean.com/settings/security named "Vagrant"
2. **Repositories:**
    1. **Bitbucket** sign-up and configuration
        1. Create an account at https://bitbucket.org
            1. Place the email address that you used to sign up for Bitbucket at `~/configuration.yml["company"]["bitbucket_username"]`
            2. Place the password of the account for Bitbucket at `~/configuration.yml["company"]["bitbucket_password"]`
    2. **GitHub** sign-up and configuration
        1. Create an account at https://github.com
            1. Place the email address that you used to sign up for GitHub at `~/configuration.yml["company"]["github_username"]`
            2. Place the password of the account for GitHub at `~/configuration.yml*["company"]["github_password"]`
3. **Automated Deployments:**
    1. **Amazon Web Services** (AWS) EC2 sign-up and configuration (Required for Bamboo)
        1. Create an AWS account https://portal.aws.amazon.com/gp/aws/developer/registration
        2. Sign in to your new AWS console https://console.aws.amazon.com
        3. Go to your AWS Identity and Access Management (IAM) Users Dashboard https://console.aws.amazon.com/iam/home#users
            1. Create a "Bamboo" user.
            2. Please note both the Access Key ID and Secret Access Key.
        4. Go to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Create a "Bamboo" group.
            2. Attach the "AmazonEC2FullAccess" policy to the "Bamboo" group.
        5. Go back to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Select your newly created "Bamboo" group.
            2. Select Add Users to Group and add your newly created "Bamboo" user.
    2. **Bamboo** sign-up and configuration
        1. Create a Bamboo Cloud account at https://www.atlassian.com/software/bamboo
        2. Sign in to your new custom Bamboo instance https://[your-name-here].atlassian.net
        3. Go to your Elastic Bamboo configuration https://[your-name-here].atlassian.net/builds/admin/elastic/editElasticConfig.action
            1. Set your AWS EC2 "Bamboo" Access Key ID and Secret Access Key
        4. Place your Bamboo base URL at `~/configuration.yml["company"]["bamboo_base_url"]`, the format should be https://[your-name-here].atlassian.net/builds/
        5. Place your Bamboo username (usually admin) at `~/configuration.yml["company"]["bamboo_username"]`
        6. Place your Bamboo password (usually admin) at `~/configuration.yml["company"]["bamboo_password"]`
        7. Click Create > Create a new plan from the header:
            1. Create Project and create TEST plan.
            * **Project and build plan name**
                1. Project > New Project
                2. Project name: Catapult
                3. Project key: CAT
                4. Plan name: test
                5. Plan key: TEST
                6. Plan description:
            * **Link repository to new build plan**
                1. Repository host: Link new repository > Other > GitHub
                2. Display name: Catapult
                3. Username: `~/configuration.yml["company"]["github_username"]`
                4. Password: `~/configuration.yml*["company"]["github_password"]`
                5. Repository: Load Repositories > github_username/catapult-release-management
                6. Branch: master
                7. Repository access: Allow all users to reuse the configuration of this repository
            2. Create QC plan.
            * **Project and build plan name**
                1. Project: Catapult
                4. Plan name: qc
                5. Plan key: QC
                6. Plan description:
            * **Link repository to new build plan**
                1. Repository host: Previously linked repository > github_username/catapult-release-management
            2. Create PROD plan.
            * **Project and build plan name**
                1. Project: Catapult
                4. Plan name: production
                5. Plan key: PROD
                6. Plan description:
            * **Link repository to new build plan**
                1. Repository host: Previously linked repository > github_username/catapult-release-management
4. **DNS:**
    1. **CloudFlare** sign-up and configuration
        1. Create a CloudFlare account at https://www.cloudflare.com
        2. Sign in your new CloudFlare account
        3. Visit your My Account section at https://www.cloudflare.com/a/account/my-account and scroll down to your API Key and place the token value at `~/configuration.yml["company"]["cloudflare_api_key"]`
        4. Place the email address of the email address that you used to sign up for CloudFlare at `~/configuration.yml["company"]["cloudflare_email"]`
5. **Verify Configuration:**
    1. To verify all of the configuration that you just set, open your command line and cd into your fork of Catapult, then run `vagrant status`. Catapult will confirm connection to all of the Services and inform you of any problems.

| Service                       | Description                                 | Monthly Cost |
|-------------------------------|---------------------------------------------|-------------:|
| **Hosting:**                  |                                             |              |
| - **DigitalOcean**            | ["company"]["name"]-test-redhat             | $5           |
| - **DigitalOcean**            | ["company"]["name"]-qc-redhat               | $5           |
| - **DigitalOcean**            | ["company"]["name"]-production-redhat       | $5           |
| - **DigitalOcean**            | ["company"]["name"]-test-redhat-mysql       | $5           |
| - **DigitalOcean**            | ["company"]["name"]-qc-redhat-mysql         | $5           |
| - **DigitalOcean**            | ["company"]["name"]-production-redhat-mysql | $5           |
| **Repositories:**             |                                             |              |
| - **Bitbucket**               | Private Repositories                        | Free         |
| - **GitHub**                  | Public Repositories                         | Free         |
| **Automated Deployments:**    |                                             |              |
| - **Amazon Web Services**     | Build Server                                | $1 - $15     |
| - **Bamboo**                  | Continuous Integration                      | $10          |
| **DNS:**                      |                                             |              |
| - **CloudFlare**              | test., qc., and production global DNS       | Free         |
| **Total**                     |                                             | $41 - $55    |



# Usage #

To use Catapult you will first need to [Provision Environments](#provision-environments) then [Provision Websites](#provision-websites).



## Provision Environments ##

| Environment                   | dev                                                         | test                                                          | qc                                                            | production                                                    |
|-------------------------------|-------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|
| **Server Provider**           | Local via VirtualBox                                        | Hosted via DigitalOcean                                       | Hosted via DigitalOcean                                       | Hosted via DigitalOcean                                       |
| **Server Provisioning**       | Manually via Vagrant                                        | Manually via Vagrant                                          | Manually via Vagrant                                          | Manually via Vagrant                                          |

For each **Environment** you will need to:
* **Web Servers**
    * `vagrant up ["company"]["name"]-dev-redhat`
    * `vagrant up ["company"]["name"]-test-redhat`
    * `vagrant up ["company"]["name"]-qc-redhat`
    * `vagrant up ["company"]["name"]-production-redhat`
* **Database Servers**
    * `vagrant up ["company"]["name"]-dev-redhat-mysql`
    * `vagrant up ["company"]["name"]-test-redhat-mysql`
    * `vagrant up ["company"]["name"]-qc-redhat-mysql`
    * `vagrant up ["company"]["name"]-production-redhat-mysql`



## Provision Websites ##

Adding websites to Catapult is easy. The only requirement is that the website needs to be contained in its own repo on GitHub or Bitbucket. Websites are then added to configuration.yml, a minimal addition looks like this:

```
- domain: "devopsgroup.io"
  repo: "git@github.com:devopsgroup-io/devopsgroup-io.git"
```

The following options are available:

* domain:
    * "example.com"
        * the domain name of what the website is/will be in production
* force_https:
    * true
        * rewrite all http traffic to https
* repo:
    * "git@github.com:devopsgroup-io/devopsgroup-io.git"
        * GitHub and Bitbucket over SSH are supported, HTTPS is not supported
* software:
    * "codeigniter2"
        * generates codeigniter2 database config file ~/application/config/database.php, restores database
    * "drupal6"
        * generates drupal6 database config file ~/sites/default/settings.php, resets drupal6 admin password, rsyncs ~/sites/default/files from production source, restores database
    * "drupal7"
        * generates drupal7 database config file ~/sites/default/settings.php, resets drupal7 admin password, rsyncs ~/sites/default/files from production source, restores database
    * "wordpress"
        * generates WordPress database config file ~/installers/wp-config.php, resets WordPress admin password, rsyncs ~/wp-content/uploads from production source, restores database
    * "xenforo"
        * generates xenforo database config file ~/library/config.php, restores database

* software_dbprefix:
    * "wp_"
        * usually used in Drupal for multisite installations ("wp_ is required for base Wordpress installs, Drupal has no prefix by default")
* webroot:
    * "www"
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash

Once the new website is committed to your Catapult fork on the master branch, it's time to provision your servers, below are commands on how to do so. Once a website is provisioned, then Bamboo Automated Deployments following Gitflow and SCRUM will kick in.

| Environment                   | dev                                                         | test                                                          | qc                                                            | production                                                    |
|-------------------------------|-------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|
| **Running Branch**            | *develop*                                                   | *develop*                                                     | *master*                                                      | *master*                                                      |
| **Upstream Database**         | Restore from *develop* ~/_sql folder of website repo        | Daily backup to *develop* ~/_sql folder of website repo       | Restore from *master* ~/_sql folder of website repo           | Restore from *master* ~/_sql folder of website repo           |
| **Downstream Database**       | Restore from *develop* ~/_sql folder of website repo        | Restore from *develop* ~/_sql folder of website repo          | Restore from *master* ~/_sql folder of website repo           | Daily backup to *develop* ~/_sql folder of website repo       |
| **Automated Deployments**     | Manually via Vagrant                                        | Automatically via Bamboo (watch for new commits to *develop*) | Automatically via Bamboo (watch for new commits to *master*)  | Manually via Bamboo                                           |
| **New Website Provisioning**  | Manually via Vagrant                                        | Manually via Vagrant                                          | Manually via Vagrant                                          | Manually via Vagrant                                          |

**New Website Provisioning** requires for each **Environment** to be provisioned via Vagrant:
* **Web Servers**
    * `vagrant provision ["company"]["name"]-dev-redhat`
    * `vagrant provision ["company"]["name"]-test-redhat`
    * `vagrant provision ["company"]["name"]-qc-redhat`
    * `vagrant provision ["company"]["name"]-production-redhat`
* **Database Servers**
    * `vagrant provision ["company"]["name"]-dev-redhat-mysql`
    * `vagrant provision ["company"]["name"]-test-redhat-mysql`
    * `vagrant provision ["company"]["name"]-qc-redhat-mysql`
    * `vagrant provision ["company"]["name"]-production-redhat-mysql`



# Contributing #

The open source community is an awesome thing, we hope Catapult is of use to you, and if you develop a feature that you think would benefit everyone, please submit a pull request.  When you first setup Catapult a develop branch is created for you under your forked repository with an upstream set to `https://github.com/devopsgroup-io/catapult-release-management.git` so that you can easily create a pull request. Also keep in mind when closing issues to submit a pull requst that includes [GitHub's: Closing issues via commit messages](https://help.github.com/articles/closing-issues-via-commit-messages/).



## Versioning ##

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards-compatible manner, and
3. PATCH version when you make backwards-compatible bug fixes.

See http://semver.org/ for more information.
