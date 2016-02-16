# Catapult #
<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/repositories/apache/_default_/svg/catapult.svg" alt="Catapult" width="200">

:boom: **Catapult** is a pre-defined website and workflow management platform built from leading and affordable technology.

:earth_americas: **Our mission** is to create a lean platform that orchestrates every DevOps task of a common website's life-cycle.

:rocket: **Our vision** is to afford developers an accelerated path to reducing risk and increasing performance at minimal cost.

<br>

**Do you need a website and workflow management platform?** Here are a few triggers.

* Production is down.
* We need a test site.
* Why is this costing so much?
* Are my environments safe? 
* Is my website backed up?
* Can I easily scale my website for more traffic?
* What is my uptime?

*Go ahead, give* **Catapult** *a* **shot**.



## Security Disclosure ##

Security is very important to us. If you have any issue regarding security, 
please disclose the information responsibly by sending an email to 
security@devopsgroup.io and not by creating a GitHub issue.



## Platform Overview ##

Catapult leverages the following technologies and technology services to implement key components of DevOps.

* **Configuration Management**
    * Catapult
    * Encryption - GnuPG
* **Source Code Management**
    * Catapult - Git (via GitHub)
    * Websites - Git (via GitHub or Bitbucket)
* **Environment Management**
    * Vagrant
* **Development Virtualization**
    * VirtualBox
* **Cloud Hosting**
    * DigitalOcean
* **DNS Management**
    * CloudFlare
* **Continuous Integration**
    * Automated Deployments - Bamboo
    * Build Server - Amazon Web Services (AWS)
* **Monitoring**
    * Server Resources and Uptime - New Relic Servers
    * Application - New Relic APM
    * Browser - New Relic Browsers
    * Website Uptime - \*New Relic Synthetics

\* This technology is currently not integrated into Catapult due to limitations of the service - manual configuration is required.



## Supported Software ##

Catapult supports the following software:

* Any PHP project compatible with PHP 5.4
    * as limited by CentOS 7.2
* CodeIgniter 2.x
* CodeIgniter 3.x
* Drupal 6.x, Drupal 7.x
    * as required by Drush 7.0.0
* SilverStripe 2.x
* WordPress 3.5.2+, WordPress 4.x
    * as required by WP-CLI
* XenForo 1.x



## Competition ##

The free market and competition is great - it pushes the envelope of innovation. Here, we compare similar platforms to shed light on where we are and we're headed. Catapult's approach is holistic, meaning, there are no optional features - the platform includes everything in its default state and its default state is the only state of the platform. Some platforms offer and support optional third-party features that need configured - these are excluded.

Platform Feature | Catapult | Pantheon | Acquia
-----------------|----------|----------|--------
Source                              | Open                           | Closed                    | Closed
Feature Set                         | Bundled                        | Separated                 | Separated
Minimum Bundled<br>Monthly Cost     | $40                            | $400                      | $134
Methodology                         | Scrum                          | :x:                       | :x:
Workflow                            | Git Flow                       | Git Flow                  | Git Flow
Workflow Model                      | Upstream or Downstream         | :x:                       | :x:
Environments                        | LocalDev, Test, QC, Production | Multidev, Dev, Test, Live | Dev Desktop, Dev, Stage, Prod
Approach                            | Virtual Machine                | Container                 | Virtual Machine
Data Center                         | DigitalOcean                   | Rackspace                 | AWS
Scaling                             | \*Resize                       | Smooth                    | Resize
Development Environment             | Unlimited Local                | 5 Cloud                   | Unlimited Local
Development Environment<br>Approach | Exact                          | Exact                     | Similar
Dashboard - Control                 | CLI                            | CLI & Web                 | CLI & Web
Dashboard - Monitor                 | CLI & \*Web                    | CLI & Web                 | CLI & Web
Git                                 | GitHub & Bitbucket             | Proprietary               | Proprietary 
DNS Management                      | CloudFlare                     | :x:                       | :x: 
HTTPS                               | Free                           | $30/mo + $cert            | $cert
Monitoring                          | New Relic                      | Proprietary               | Proprietary
Supported Software                  | Numerous                       | 2                         | 1

\* Catapult introduces new features on a regular basis - this feature is highlighted as a milestone for future release.
See an error or have a suggestion? Email competition@devopsgroup.io



## Table of Contents ##

- [Catapult](#catapult)
    - [Platform Overview](#platform-overview)
    - [Security Disclosure](#security-disclosure)
    - [Supported Software](#supported-software)
    - [Competition](#competition)
    - [Table of Contents](#table-of-contents)
- [Setup Catapult](#setup-catapult)
    - [Developer Setup](#developer-setup)
    - [Instance Setup](#instance-setup)
    - [Services Setup](#services-setup)
- [Setup Environments](#setup-environments)
    - [Provision Environments](#provision-environments)
    - [Configure Automated Deployments](#configure-automated-deployments)
- [Release Management](#release-management)
    - [Catapult Configuration](#catapult-configuration)
        - [Websites](#websites)
    - [Website Development](#website-development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
    - [Releases](#releases)
- [Community](#community)



# Setup Catapult #

Catapult requires a [Developer Setup](#developer-setup), [Instance Setup](#instance-setup), and [Services Setup](#services-setup) as described in the following sections.

**Please Note:** It is advised to turn off any antivirus software that you may have installed during Developer Setup and Usage of Catapult, because necessary tasks such as forwarding ports and writing hosts files may be blocked.



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
    1. Fork https://github.com/devopsgroup-io/catapult and clone via SourceTree or the git utility of your choice.
2. **Vagrant Plugins**
    1. Open your command line and cd into the newly cloned repository and install the following Vagrant plugins.
        1. `vagrant plugin install vagrant-aws` [![Gem](https://img.shields.io/gem/dt/vagrant-aws.svg)](https://rubygems.org/gems/vagrant-aws)
        2. `vagrant plugin install vagrant-digitalocean` [![Gem](https://img.shields.io/gem/dt/vagrant-digitalocean.svg)](https://rubygems.org/gems/vagrant-digitalocean)
            * We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-digitalocean)
        3. `vagrant plugin install vagrant-hostmanager` [![Gem](https://img.shields.io/gem/dt/vagrant-hostmanager.svg)](https://rubygems.org/gems/vagrant-hostmanager)
            * We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-hostmanager)
        4. `vagrant plugin install vagrant-vbguest` [![Gem](https://img.shields.io/gem/dt/vagrant-vbguest.svg)](https://rubygems.org/gems/vagrant-vbguest)
3. **SSH Key Pair**
    1. You will need to create a *passwordless* SSH key pair that will drive authentication for Catapult.
        1. For instructions please see https://help.github.com/articles/generating-ssh-keys/
        2. Place the newly created *passwordless* SSH key pair id_rsa and id_rsa.pub in the ~/secrets/ folder.
4. **GPG Key**
    1. You will need to create your team's gpg_key that will be the single key that encrypts all of your configuration and secrets for your instance.
        1. NEVER SHARE THE KEY WITH ANYONE OTHER THAN YOUR TEAM.
        3. Spaces are not permitted and must be at least 20 characters.
        4. To create a strong key, please visit https://xkpasswd.net/
        5. It is recommended to print a QR code of the key to distribute to your team, please visit http://educastellano.github.io/qr-code/demo/
        6. Remember; security is 99% process and 1% technology.
5. **GPG Edit Mode**
    1. When **GPG Edit Mode** is enabled (disabled by default) the following files are encrypted using your **GPG Key**:
        1. ~/secrets/id_rsa as ~/secrets/id_rsa.gpg
        2. ~/secrets/id_rsa.pub as ~/secrets/id_rsa.pub.gpg
        3. ~/secrets/configuration.yml as ~/secrets/configuration.yml.gpg
    2. To enable **GPG Edit Mode**, set `~/secrets/configuration-user.yml["settings"]["gpg_edit"]` to true.
    3. Once gpg_edit is set to true and while on your fork's develop branch, run `vagrant status`, this will encrypt your configuration that you will then be able to commit and push safely to your public Catapult fork.



## Services Setup ##

Catapult uses several third-party services to pull everything off - below is a list of the required services and sign-up and configuration steps.

Service | Description | Monthly Cost
--------|-------------|-------------
**Cloud Hosting:** | |
DigitalOcean | Test Web Server | \*$5+
DigitalOcean | Test Database Server | \*$5+
DigitalOcean | QC Web Server | \*$5+
DigitalOcean | QC Database Server | \*$5+
DigitalOcean | Production Web Server | \*$5+
DigitalOcean | Production Database Server | \*$5+
**Repositories:** | |
Bitbucket | Private Repositories | Free
GitHub | Public Repositories | Free
**Continuous Integration:** | |
Amazon Web Services | Build Server | \*$0+
Bamboo | Continuous Integration | $10
**DNS:** | |
CloudFlare | Cloud DNS | Free
**Monitoring:** | |
New Relic | Application, Browser, and Server Monitoring | Free
**Total** | | $40+
\* Depending on load, resources may need to be increased. However, a few websites with builds running irregularly will not incur over a couple dollars more per month.

1. **Cloud Hosting:**    
    1. **DigitalOcean** sign-up and configuration
        1. Create an account at http://digitalocean.com
           * Get a $10 credit and give us $25 once you spend $25 https://www.digitalocean.com/?refcode=6127912f3462
        2. Go to your DigitalOcean Applications & API Dashboard https://cloud.digitalocean.com/settings/api
            1. Create a Personal Access Token named "Vagrant" and place the token value at `~/secrets/configuration.yml["company"]["digitalocean_personal_access_token"]`
        3. Go to your DigitalOcean Security Dashboard https://cloud.digitalocean.com/settings/security
            1. Add a new SSH Key named "Vagrant" with your newly created id_rsa.pub from ~/secrets/id_rsa.pub key 
    2. **Amazon Web Services** (AWS) sign-up and configuration
        1. Create an account https://portal.aws.amazon.com/gp/aws/developer/registration
        2. Sign in to your new AWS console https://console.aws.amazon.com
        3. Go to your AWS Identity and Access Management (IAM) Users Dashboard https://console.aws.amazon.com/iam/home#users
            1. Create a "Catapult" user.
            2. Place the Access Key ID at `~/secrets/configuration.yml["company"]["aws_access_key"]`
            3. Place the Secret Access Key at `~/secrets/configuration.yml["company"]["aws_secret_key"]`
        4. Go to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Create a "Catapult" group.
            2. Attach the "AmazonEC2FullAccess" policy to the "Catapult" group.
        5. Go back to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Select your newly created "Catapult" group.
            2. Select Add Users to Group and add your newly created "Catapult" user.
        6. Go to your AWS EC2 Key Pairs Dashboard https://console.aws.amazon.com/ec2/home#KeyPairs
            1. Click Import Key Pair
            2. Add your newly created id_rsa.pub from ~/secrets/id_rsa.pub key
            3. Set the Key pair name to "Catapult"
        7. Go to your AWS EC2 Security Groups Dashboard https://console.aws.amazon.com/ec2/home#SecurityGroups
            1. Select the "default" Group Name
            2. Select the Inbound tab and click Edit
            3. Change Source to "Anywhere"
            4. Click Save
2. **Repositories:**    
    Bitbucket provides free private repositories and GitHub provides free public repositories, you will need to sign up for both. If you already have Bitbucket and GitHub accounts you may use them, however, it's best to setup a [machine user](https://developer.github.com/guides/managing-deploy-keys/#machine-users) if you're using Catapult with your team.
    1. **Bitbucket** sign-up and configuration
        1. Create an account at https://bitbucket.org
            1. Place the username (not the email address) that you used to sign up for Bitbucket at `~/secrets/configuration.yml["company"]["bitbucket_username"]`
            2. Place the password of the account for Bitbucket at `~/secrets/configuration.yml["company"]["bitbucket_password"]`
        2. Add your newly created id_rsa.pub from ~/secrets/id_rsa.pub key in https://bitbucket.org/account/user/`your-user-here`/ssh-keys/ named "Catapult"
    2. **GitHub** sign-up and configuration
        1. Create an account at https://github.com
            1. Place the username (not the email address) that you used to sign up for GitHub at `~/secrets/configuration.yml["company"]["github_username"]`
            2. Place the password of the account for GitHub at `~/secrets/configuration.yml["company"]["github_password"]`
        2. Add your newly created id_rsa.pub from ~/secrets/id_rsa.pub key in https://github.com/settings/ssh named "Catapult"
3. **Automated Deployments:**
    2. **Bamboo** sign-up and configuration
        1. Create a Bamboo Cloud account at https://www.atlassian.com/software/bamboo
        2. Sign in to your new custom Bamboo instance https://[your-name-here].atlassian.net
        3. Place your Bamboo base URL at `~/secrets/configuration.yml["company"]["bamboo_base_url"]`, the format should be https://[your-name-here].atlassian.net/builds/
        4. Place your Bamboo username (usually admin) at `~/secrets/configuration.yml["company"]["bamboo_username"]`
        5. Place your Bamboo password (usually admin) at `~/secrets/configuration.yml["company"]["bamboo_password"]`
        6. Click the settings gear from the top right in the header and select Elastic instances:
            1. Click Configuration from the left
            2. Click Edit configuration
                1. **Amazon Web Services configuration**
                    1. Set your AWS EC2 "Bamboo" Access Key ID and Secret Access Key from `~/secrets/configuration.yml["company"]["aws_access_key"]` and `~/secrets/configuration.yml["company"]["aws_secret_key"]`
                    2. Region: `US East (Northern Virginia)`
                2. **Automatic elastic instance management**
                    1. Elastic instance management: `Custom`
                    2. Idle agent shutdown delay: `10`
                    3. Allowed non-Bamboo instances: `1`
                    4. Maximum number of instances to start at once: `2`
                    5. Number of builds in queue threshold: `1`
                    6. Number of elastic builds in queue threshold: `1`
                    7. Average queue time threshold: `2`
                3. Click Save
        7. Click the settings gear from the top right in the header and select Elastic instances:
            1. Click Image configurations from the left
                1. Disable all of the elastic images
                2. Create elastic image configuration:
                    1. Name: `Catapult`
                    2. AMI ID: `ami-eb5b8080`
                    3. Instance type: `T2 Burstable Performance Micro`
                    4. Availability Zone: `Chosen by EC2`
                    5. Product: `Linux/UNIX`
                    6. Click Save
        8. Click Create > Create a new plan from the header:
            1. **Create Catapult Project and create TEST Plan**
                * *Project and build plan name*
                    1. Project > New Project
                    2. Project name: Catapult
                    3. Project key: CAT
                    4. Plan name: TEST
                    5. Plan key: TEST
                    6. Plan description:
                * *Link repository to new build plan*
                    1. Repository host: Other > None
            2. **Create QC Plan**
                * *Project and build plan name*
                    1. Project: Catapult
                    4. Plan name: QC
                    5. Plan key: QC
                    6. Plan description:
                * *Link repository to new build plan*
                    1. Repository host: Other > None
            2. **Create PROD Plan**
                * *Project and build plan name*
                    1. Project: Catapult
                    4. Plan name: PRODUCTION
                    5. Plan key: PROD
                    6. Plan description:
                * *Link repository to new build plan*
                    1. Repository host: Other > None
4. **DNS:**    
    1. **CloudFlare** sign-up and configuration
        1. Create a CloudFlare account at https://www.cloudflare.com
        2. Sign in to your new CloudFlare account
        3. Visit your My Account section at https://www.cloudflare.com/a/account/my-account and scroll down to your API Key and place the token value at `~/secrets/configuration.yml["company"]["cloudflare_api_key"]`
        4. Place the email address of the email address that you used to sign up for CloudFlare at `~/secrets/configuration.yml["company"]["cloudflare_email"]`
5. **Monitoring:**
    1. **New Relic** sign-up and configuration
        1. Create a New Relic account at http://newrelic.com/
        2. Sign in to your New Relic account
        3. Go to your Account Settings > Integrations > API keys.
        4. Generate and place your REST API key at `~/secrets/configuration.yml["company"]["newrelic_api_key"]`
        3. Go to your Account Settings > Account > Summary.
        5. Place your License key at `~/secrets/configuration.yml["company"]["newrelic_license_key"]`
6. **Verify Configuration:**    
    1. To verify all of the configuration that you just set, open your command line and cd into your fork of Catapult, then run `vagrant status`. Catapult will confirm connection to all of the Services and inform you of any problems.



# Setup Environments #

To start using Catapult you will need to [Provision Environments](#provision-environments) and [Configure Automated Deployments](#configure-automated-deployments).



## Provision Environments ##

Environment | LocalDev | Test | QC | Production
------------|----------|------|----|-----------
**Server Provider** | Locally via VirtualBox | Hosted via DigitalOcean | Hosted via DigitalOcean | Hosted via DigitalOcean
**Server Provisioning** | Manually via Vagrant | Manually via Vagrant | Manually via Vagrant | Manually via Vagrant

For each **Environment** you will need to:

* **Web Servers**
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-dev-redhat`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-test-redhat`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-qc-redhat`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-production-redhat`
* **Database Servers**
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-dev-redhat-mysql`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-test-redhat-mysql`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-qc-redhat-mysql`
    * `vagrant up ~/secrets/configuration.yml["company"]["name"]-production-redhat-mysql`



## Configure Automated Deployments ##

Once the Web and Database Servers are up and running, it's then time to configure your Bamboo Catapult project's TEST, QC, and PROD plans.

1. Sign in to your new custom Bamboo instance https://[your-name-here].atlassian.net
2. Click Build > All build plans from the header:
3. From the Build Dashboard and under the Catapult project:
    * **Configure Catapult Project TEST Plan**
        1. Click the edit icon for the TEST plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["test"]["servers"]["redhat"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "test" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["test"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "test" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
            7. Click Save
    * **Configure Catapult Project QC Plan**
        1. Click the edit icon for the QC plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["qc"]["servers"]["redhat"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "qc" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["qc"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "qc" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
            7. Click Save
    * **Configure Catapult Project PRODUCTION Plan**
        1. Click the edit icon for the PRODUCTION plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["production"]["servers"]["redhat"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "production" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["production"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "production" "https://github.com/your-name-here/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
            7. Click Save



# Release Management #

Catapult follows Gitflow for its configuration and development model - each environment runs a specific branch and changesets are introduced into each environment by pull requests from one branch to the next.

<img src="https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/05.svg" alt="Gitflow" width="600">
[1](#references)


Environment | LocalDev | Test | QC | Production
------------|----------|------|----|-----------
**Running Branch**                       | *develop*                                                   | *develop*                                                         | *release*                                                      | *master*
**Deployments**                          | Manually via `vagrant provision`                            | Automatically via Bamboo (new commits to **develop**)             | Automatically via Bamboo (new commits to **release**)          | Manually via Bamboo
**Testing Activities**                   | Component Test                                              | Integration Test, System Test                                     | Acceptance Test, Release Test                                  | Operational Qualification
**Scrum Activity**                       | Sprint Start: Development of User Stories                   | Daily Scrum                                                       | Sprint Review                                                  | Sprint End: Accepted Product Release
**Scrum Roles**                          | Development Team                                            | Scrum Master, Development Team, Product Owner (optional)          | Scrum Master, Development Team, Product Owner                  | Product Owner
**Downstream Workflow - Database**       | Restore from **develop** ~/_sql folder of website repo      | Restore from **develop** ~/_sql folder of website repo            | Restore from **release** ~/_sql folder of website repo         | Backup to **develop** ~/_sql folder of website repo during deploy
**Upstream Workflow - Database**         | Restore from **develop** ~/_sql folder of website repo      | Backup to **develop** ~/_sql folder of website repo during deploy | Restore from **release** ~/_sql folder of website repo         | Restore from **master** ~/_sql folder of website repo
**Downstream Workflow - Software Files** | rsync files from **Production** if untracked                | rsync files from **Production** if untracked                      | rsync files from **Production** if untracked                   | --
**Upstream Workflow - Software Files**   | rsync files from **Test** if untracked                      | --                                                                | rsync files from **Test** if untracked                         | rsync files from **Test** if untracked



## Catapult Configuration ##



### Websites ###

Adding websites to Catapult is easy. The only requirement is that the website needs to be contained in its own repo at GitHub or Bitbucket. Websites are then added to configuration.yml, a minimal addition looks like this:

```
websites:
  apache:
  - domain: devopsgroup.io
    repo: git@github.com:devopsgroup-io/devopsgroup-io.git
```

The following options are available:

* domain:
    * `example.com`
        * the domain name of what the website is/will be in Production
        * a maximum of one subdomain is supported (subdomain.example.com)
        * this drives the domains of LocalDev (via hosts file) and Test, QC, Production (via CloudFlare)
        * dev.example.com, test.example.com, qc.example.com, example.com
* domain_tld_override:
    * `mycompany.com`
        * a domain name that will override the tld of the domain for when you do not have control of the domain (example.com), but still need a LocalDev and externally accessible Test and QC instance
        * this drives the domains of LocalDev (via hosts file) and Test, QC, Production (via CloudFlare)
            * PLEASE NOTE: When removing this option from a website with `software`, you need to manually replace URLs in the database respective to the `software_workflow` option.
                * ie `vagrant ssh mycompany.com-test-redhat-mysql`
                * `php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/example.com/(webroot if applicable)" search-replace ":\/\/(www\.)?(dev\.|test\.)?(example\.com\.mycompany\.com)" "://example.com" --regex`
        * dev.example.com, test.example.com, qc.example.com, example.com are replaced by dev.example.com.mycompany.com, test.example.com.mycompany.com, qc.example.com.mycompany.com, example.com.mycompany.com
* force_auth:
    * `example`
        * forces http basic authentication in Test, QC, and Production
        * `example` is both the username and password
* force_auth_exclude:
    * `["test","qc","production"]`
        * array of exclusions exclusive to the force_auth option
* force_https:
    * `true`
        * rewrite all http traffic to https
        * subdomains are not supported as limited by CloudFlare
        * you will receive an unsigned cert error in LocalDev
* repo:
    * `git@github.com:devopsgroup-io/devopsgroup-io.git`
        * GitHub and Bitbucket over SSH are supported, HTTPS is not supported
* software:
    * `codeigniter2`
        * generates codeigniter2 database config file ~/application/config/database.php
        * rsyncs untracked ~/uploads
        * sets permissions for ~/uploads
        * dumps and restores database at ~/sql
    * `codeigniter3`
        * generates codeigniter3 database config file ~/application/config/database.php
        * rsyncs untracked ~/uploads
        * sets permissions for ~/uploads
        * dumps and restores database at ~/sql
    * `drupal6`
        * generates drupal6 database config file ~/sites/default/settings.php
        * rsyncs untracked ~/sites/default/files
        * sets permissions for ~/sites/default/files
        * dumps and restores database at ~/sql
        * invokes drush updatedb
        * resets drupal6 admin password
    * `drupal7`
        * generates drupal7 database config file ~/sites/default/settings.php
        * rsyncs untracked ~/sites/default/files
        * sets permissions for ~/sites/default/files
        * dumps and restores database at ~/sql
        * invokes drush updatedb
        * resets drupal7 admin password
    * `silverstripe`
        * generates silverstripe database config file ~/mysite/_config.php
        * restores newest database from ~/sql
    * `wordpress`
        * generates wordpress database config file ~/installers/wp-config.php
        * rsyncs untracked ~/wp-content/uploads
        * sets permissions for ~/wp-content/uploads
        * dumps and restores database at ~/sql
        * invokes wp-cli core update-db
        * resets wordpress admin password
    * `xenforo`
        * generates xenForo database config file ~/library/config.php
        * rsyncs untracked ~/data and ~/internal_data
        * sets permissions for ~/data and ~/internal_data
        * dumps and restores database at ~/sql
* software_dbprefix:
    * `wp_`
        * `wp_` is required for base Wordpress installs, Drupal has no prefix by default
* software_workflow:
    * `downstream`
        * Production is the source for the database and software upload directories
        * this option is used when maintaining a website
    * `upstream`
        * Test is the source for the database and software upload directories
        * this option is used when launching a new website
* webroot:
    * `www/`
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash



## Website Development ##

Once you Provision Websites and it's time to work on a website, there are a few things to consider:

* Using the `software_workflow` flag for `upstream` websites is great, you can develop your code in LocalDev then have anyone in your company enter content into Drupal, Wordpress, etc. However, in the cercumstance that you absolutely need to move your LocalDev database `upstream`, it's as easy as saving a .sql dump to your website's repository develop branch under the _sql folder with today's date (following the YYYYMMDD.sql format). You can then `vagrant rebuild` the `~/secrets/configuration.yml["company"]["name"]-test-redhat-mysql` server and it will restore from your new sql dump.



# Troubleshooting #

Below is a log of service related troubleshooting, if you're still having issues with Catapult, [submit a GitHub Issue](https://github.com/devopsgroup-io/catapult/issues/new).

* **DigitalOcean**
    * [09-01-2015] vagrant rebuild was failing with a `The configured shell (config.ssh.shell) is invalid and unable to properly execute commands.` it is due to DigitalOcean's API not re-inserting the SSH key that was originally used during the first vagrant up (creation of the droplet). To rebuild, you must use the DigitalOcean console, run through the first root password reset workflow that was emailed to you, then vi /etc/sudoers and remove the Defaults requiretty line and save and exit. You can then run vagrant provision successfully.
* **Git**
    * [09-08-2015] Some database dumps exceed 100MB, so it's recommened to use Bitbucket in those instances as Catapult auto-commits database dumps to your website's repository, up to 500MB worth of database dumps or the one, newest database dump. [Bitbucket](https://help.github.com/articles/what-is-my-disk-quota/) has a 2GB hard repo push limit with no documented file limit and [GitHub](https://help.github.com/articles/what-is-my-disk-quota/) has a 1GB soft repo limit with a 100MB file size limit.
* **Vagrant**
   * [02-04-2015] When upgrading Vagrant you may run into errors - the most common issue are mismatched plugins, running this command has a good chance of success `sudo rm -Rf ~/.vagrant.d/gems/ && sudo rm ~/.vagrant.d/plugins.json`



# Contributing #

So you want to contribute... Great! Open source projects like Catapult succeed or fail upon the involvement of a thriving community of developers, who often offer various levels of code skills and time commitment. Here are some ways you can begin contributing right away, at whatever level is most comfortable for you.

  * Submit a feature
  * Report a bug
  * Verify and track down a reported bug
  * Add documentation to the README
  * Answer project specific questions
  * Blog about your experiences with Catapult

When you first setup Catapult a `develop-catapult` branch is created for you under your forked repository, with an upstream set to `https://github.com/devopsgroup-io/catapult.git` so that you can easily create a pull request. Also keep in mind when closing issues to submit a pull request that includes [GitHub's: Closing issues via commit messages](https://help.github.com/articles/closing-issues-via-commit-messages/).



## Releases ##

Releases are driven by the devopsgroup.io team and occur when accepting new pull requests from contributors like you. Releases follow Semantic Versioning 2.0.0, given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards-compatible manner, and
3. PATCH version when you make backwards-compatible bug fixes.

In addition, the release will be prefaced with a `v` (v1.0.0) to conform standard practice.

During a new release, the version number in VERSION.yml will be incremented and tagged with the same version number along with a [GitHub Release](https://help.github.com/articles/about-releases/).

See http://semver.org/spec/v2.0.0.html for more information.



# Community #


## Partnerships ##

The Catapult team values partnerships and the great services and teams that have built them.

* [01-28-2016] Pantheon provides feedback
* [01-22-2016] New Relic provides private beta access to their Synthetics API along side Breather, Carfax, Ring Central, Rackspace, and IBM.



## Conferences ##

Catapult is making the conference tour! We plan to attend the following the conferences, with more to come. Get a chance to see Catapult in action, presented by it's core developers.

* Spring 2016 [04-08-2016] [Drupaldelphia](http://drupaldelphia.com/)
* Summer 2016 [Wharton Web Conference](http://www.sas.upenn.edu/wwc/)
* Winter 2016 [WordCamp US](http://us.wordcamp.org/)



## Local Events ##

Catapult will also be seen throughout local meetups in the Philadelphia and Greater Philadelphia area! Get a chance to meet the team and engage at a personal level.

* [Philly Tech Meetup](http://www.meetup.com/philly-tech/) 4k+ technologists
* [Princeton Tech ](http://www.meetup.com/Princeton-Tech/) 3.5k+ technologists
* [Technical.ly Philly](http://www.meetup.com/Technically-Philly/) 3k+
* [Philadelphia WordPress Meetup Group](http://www.meetup.com/philadelphia-wordpress-meetup-group/) 1.5k+ technologists
* [Philly DevOps](http://www.meetup.com/PhillyDevOps/) 700+ technologists
* [Greater Philadelphia Drupal Meetup Group](http://www.meetup.com/drupaldelphia/) 500+ technologists



# References #
1. Atlassian. Comparing Workflows. https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow. Accessed February 15, 2016.
