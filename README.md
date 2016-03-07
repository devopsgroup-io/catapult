# Catapult #
<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/repositories/apache/_default_/svg/catapult.svg" alt="Catapult" width="200">

:boom: **Catapult** is a complete website and workflow management platform built from leading and affordable technologies.

:earth_americas: **Our mission** is to create a lean platform which orchestrates DevOps for website lifecycles with familiar technologies.

:rocket: **Our vision** is to afford organizations reduced risk and improved performance while lowering barriers to entry.

<br>

**Do you need a website and workflow management platform?** Here are a few triggers.

* Production is down.
* We need a test site.
* Why is this costing so much?
* Are my environments safe? 
* Is my website backed up?
* How quickly can I recover my website after a disaster?
* Can I easily scale my website for more traffic?
* What is my uptime?

**What makes Catapult different?**

* Catapult is open sourced.
* Catapult is a single-state architecture - you will always be driving a fully optioned Ferrari.
* Catapult is a configuration framework that invokes platform native shell scripts rather than using traditional configuration management tools such as Chef, Puppet, Salt.
* Catapult overlays seamlessly with Scrum working methodology.
* Catapult features Gitflow workflow and branch-based environments.
* Catapult features a unique workflow model - upstream or downstream.
* Catapult is extremely cost effective.

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
    * Website Uptime - New Relic Synthetics



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
Source                              | Open                           | Closed                        | Closed
Feature Set                         | Bundled                        | Separated                     | Separated
Minimum Bundled<br>Monthly Cost     | $40                            | $400                          | $134
Methodology                         | Scrum                          | :x:                           | :x:
Workflow                            | Git Flow                       | Git Flow                      | Git Flow
Workflow Model                      | Upstream or Downstream         | :x:                           | :x:
Environments                        | LocalDev, Test, QC, Production | Multidev, Dev, Test, Live     | Dev Desktop, Dev, Stage, Prod
Exacting Configuration              | :white_check_mark:             | :x:<sup>[2](#references)</sup>| :x:<sup>[3](#references)</sup>
Approach                            | Virtual Machine                | Container                     | Virtual Machine
Data Center                         | DigitalOcean and AWS           | Rackspace                     | AWS
Scaling                             | Vertical                       | Horizontal                    | Vertical
Scaling Management                  | *Manual                        | Automatic                     | Manual
Development Environment             | Unlimited Local                | 5 Cloud                       | Unlimited Local
Development Environment<br>Approach | Exact                          | Exact                         | Similar
Dashboard - Control                 | CLI                            | CLI & Web                     | CLI & Web
Dashboard - Monitor                 | CLI & \*Web                    | CLI & Web                     | CLI & Web
Git                                 | GitHub & Bitbucket             | Proprietary                   | Proprietary 
Managed DNS                         | CloudFlare                     | :x:                           | :x: 
Managed HTTPS                       | Free                           | $30/mo + $cert                | $cert
Managed Monitoring                  | New Relic                      | Proprietary                   | Proprietary
Supported Software                  | Numerous                       | 2                             | 1

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
        - [Company](#company)
        - [Environments](#environments)
        - [Websites](#websites)
    - [Website Development](#website-development)
    - [Performance Testing](#performance-testing)
        - [Website Concurrency Maxiumum](#website-concurrency-maximum)
        - [Interpreting Apache AB Results](#interpreting-apache-ab-results)
    - [Disaster Recovery](#disaster-recovery)
        - [Server Rebuilding](#server-rebuilding) 
        - [Website Rollbacks](#website-rollbacks) 
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
    2. Using OSX ? Please ensure Xcode Command Line Tools are installed by running `xcode-select --install` from Terminal
2. **VirtualBox**
    1. Please download and install from https://www.virtualbox.org/wiki/Downloads
3. **SourceTree**
    1. Please download and install from https://www.sourcetreeapp.com/
4. **Sublime Text 3**
    1. Please download and install from http://www.sublimetext.com/3
5. **GPG2**
    1. Using OSX? Please download and install GPG Suite https://gpgtools.org
    2. Using Linux? If being prompted by the Passphrase GUI Agent, comment out 'use-agent' in ~/.gnupg/gpg.conf
    3. Using Windows? Please download and install Gpg4win from http://gpg4win.org/download.html


## Instance Setup ##

Catapult is quick to setup. Fork the Github repository and start adding your configuration.

1. **Fork Catapult**
    1. Fork https://github.com/devopsgroup-io/catapult and clone via SourceTree or the git utility of your choice.
2. **Vagrant Plugins**
    1. Open your command line and cd into the newly cloned repository and install the following Vagrant plugins.
        1. `vagrant plugin install vagrant-aws`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-aws.svg)](https://rubygems.org/gems/vagrant-aws)
        2. `vagrant plugin install vagrant-digitalocean`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-digitalocean.svg)](https://rubygems.org/gems/vagrant-digitalocean) We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-digitalocean)
        3. `vagrant plugin install vagrant-hostmanager`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-hostmanager.svg)](https://rubygems.org/gems/vagrant-hostmanager) We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-hostmanager)
        4. `vagrant plugin install vagrant-vbguest`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-vbguest.svg)](https://rubygems.org/gems/vagrant-vbguest)
3. **SSH Key Pair**
    1. Create a *passwordless* SSH key pair - this will drive authentication for Catapult.
        1. For instructions please see https://help.github.com/articles/generating-ssh-keys/
        2. Place the newly created *passwordless* SSH key pair id_rsa and id_rsa.pub in the ~/secrets/ folder.
4. **GPG Key**
    1. Generate a GPG key - this will drive encryption for Catapult.
        1. NEVER SHARE THE KEY WITH ANYONE OTHER THAN YOUR TEAM.
        3. Spaces are not permitted and must be at least 20 characters.
        4. To create a strong key, please visit https://xkpasswd.net/
        5. Place your newly generated GPG key at `~/secrets/configuration-user.yml["settings"]["gpg_key"]`
        6. It is recommended to print a QR code of the key to distribute to your team, please visit http://educastellano.github.io/qr-code/demo/
        7. Remember! Security is 99% process and 1% technology.
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
           * [Free Stuff] Get a $10 credit and give us $25 once you spend $25 https://www.digitalocean.com/?refcode=6127912f3462
        2. Go to your DigitalOcean Applications & API Dashboard https://cloud.digitalocean.com/settings/api
            1. Create a Personal Access Token named "Vagrant" and place the token value at `~/secrets/configuration.yml["company"]["digitalocean_personal_access_token"]`
        3. Go to your DigitalOcean Security Dashboard https://cloud.digitalocean.com/settings/security
            1. Add a new SSH Key named "Vagrant" with your newly created id_rsa.pub from ~/secrets/id_rsa.pub key 
    2. **Amazon Web Services** (AWS) sign-up and configuration
        1. Create an account https://portal.aws.amazon.com/gp/aws/developer/registration
            * [Free Stuff] Receive Free Tier benefits for the first 12 months after signing up https://aws.amazon.com/ec2/pricing/
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
            * [Free Stuff] Sign-up up for New Relic and get a Data Nerd shirt! http://newrelic.com/lp/datanerd
            * [Free Stuff] Refer Catapult and get a New Relic hoodie! http://newrelic.com/referral
        2. Sign in to your New Relic account
        3. Go to your Account Settings > Integrations > API keys.
        4. Generate and place your REST API key at `~/secrets/configuration.yml["company"]["newrelic_api_key"]`
        5. Generate and place your Admin API key at `~/secrets/configuration.yml["company"]["newrelic_admin_api_key"]`
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
<sup>[1](#references)</sup>


Environment | LocalDev | Test | QC | Production
------------|----------|------|----|-----------
**Running Branch**                              | *develop*                                                   | *develop*                                                         | *release*                                                      | *master*
**Deployments**                                 | Manually via `vagrant provision`                            | Automatically via Bamboo (new commits to **develop**)             | Automatically via Bamboo (new commits to **release**)          | Manually via Bamboo
**Testing Activities**                          | Component Test                                              | Integration Test, System Test                                     | Acceptance Test, Release Test                                  | Operational Qualification
**Scrum Activity**                              | Sprint Start: Development of User Stories                   | Daily Scrum                                                       | Sprint Review                                                  | Sprint End: Accepted Product Release
**Scrum Roles**                                 | Development Team                                            | Scrum Master, Development Team, Product Owner (optional)          | Scrum Master, Development Team, Product Owner                  | Product Owner
**Downstream Software Workflow - Database**     | Restore from **develop** ~/_sql folder of website repo      | Restore from **develop** ~/_sql folder of website repo            | Restore from **release** ~/_sql folder of website repo         | Backup to **develop** ~/_sql folder of website repo during deploy
**Upstream Software Workflow - Database**       | Restore from **develop** ~/_sql folder of website repo      | Backup to **develop** ~/_sql folder of website repo during deploy | Restore from **release** ~/_sql folder of website repo         | Restore from **master** ~/_sql folder of website repo
**Downstream Software Workflow - File Store**   | rsync files from **Production** if git untracked            | rsync files from **Production** if untracked                      | rsync files from **Production** if git untracked               | --
**Upstream Software Workflow - File Store**     | rsync files from **Test** if git untracked                  | --                                                                | rsync files from **Test** if git untracked                     | rsync files from **Test** if git untracked



## Catapult Configuration ##

All instance specific configuration is stored in ~/secrets/configuration.yml and encrypted as ~/secrets/configuration.yml.gpg. There are three main sections - [Company](#company), [Environments](#environments), and [Websites](#websites).



### Company ###

The exclusive Company entry contains top-level global credentials and company information - all of which will be configured during [Setup Catapult](#setup-catapult).

* name:
    * `required: true`
        * Your company's name or your name
* email:
    * `required: true`
        * Your company's email or your email that is used for software admin accounts and virtual host admin
* timezone_redhat:
    * `required: true`
        * Your timezone in tz database format that is used to for setting within operating systems and applications
        * https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Virtualization/3.1/html/Developer_Guide/appe-REST_API_Guide-Timezones.html
* timezone_windows:
    * `required: true`
        * Your timezone in Windows Standard Format that is used to for setting within operating systems and applications
        * https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Virtualization/3.1/html/Developer_Guide/appe-REST_API_Guide-Timezones.html



### Environments ###

The setup- and maintenance-free Environments entries contain environment configurations such as IP addresses and system credentials - all of which are automatically set during [Setup Catapult](#setup-catapult) and [Setup Environments](#setup-environments).



### Websites ###

Adding websites to Catapult is driven by simple configuration. After establishing a repository at GitHub or Bitbucket, simply add entries to configuration.yml. The entries must be ordered alphabetically by domain name and all entries exist under the single `websites` key as reflected in this example:
```
websites:
  apache:
  - domain: devopsgroup.io
    repo: git@github.com:devopsgroup-io/devopsgroup-io.git
  - domain: example.com
    repo: git@github.com:example-company/example.com.git
```

The following options are available:

* domain:
    * `required: true`
    * `example: example.com`
        * the Production canonical domain name without `www.`
            * one subdomain level is supported (subdomain.example.com)
        * this drives the domains of LocalDev (via hosts file) and Test, QC, Production (via CloudFlare)
            * dev.example.com, test.example.com, qc.example.com, example.com
* domain_tld_override:
    * `required: false`
    * `default: null`
    * `example: mycompany.com`
        * a domain name under your [name server authority](https://en.wikipedia.org/wiki/Domain_Name_System#Authoritative_name_server) to append to the top-level-domain (e.g. `.com`)
            * useful when you cannot or do not wish to host the Test/QC website at the `domain`
        * appends the `domain_tld_override` for Environments
            * dev.example.com.mycompany.com, test.example.com.mycompany.com, qc.example.com.mycompany.com, example.com.mycompany.com
        * PLEASE NOTE: When removing this option from a website with `software`, you need to manually replace URLs in the database respective to the `software_workflow` option.
            * ie `vagrant ssh mycompany.com-test-redhat-mysql`
            * `php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/example.com/(webroot if applicable)" search-replace ":\/\/(www\.)?(dev\.|test\.)?(example\.com\.mycompany\.com)" "://example.com" --regex`
* force_auth:
    * `required: false`
    * `default: null`
    * `example: letmein`
        * forces [http basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) in Test, QC, and Production (see `force_auth_exclude`)
        * `letmein` is both the username and password
* force_auth_exclude:
    * `dependency: force_auth`
    * `required: false`
    * `default: null`
    * `values: ["test","qc","production"]`
        * array of Environments to exclude from the `force_auth` option
* force_https:
    * `required: false`
    * `default: false`
    * `values: true, false`
        * rewrites all http traffic to https
        * subdomains are not supported as limited by CloudFlare
        * causes an unsigned cert error in LocalDev
* repo:
    * `required: true`
    * `example: git@github.com:devopsgroup-io/devopsgroup-io.git`
        * GitHub and Bitbucket over SSH are supported, HTTPS is not supported
* software:
    * `required: false`
    * `default: null`
    * `value: codeigniter2`
        * maintains codeigniter2 database config file ~/application/config/database.php
        * rsyncs git untracked ~/uploads
        * sets permissions for ~/uploads
        * dumps and restores database at ~/_sql
        * updates url references in database
    * `value: codeigniter3`
        * maintains codeigniter3 database config file ~/application/config/database.php
        * rsyncs git untracked ~/uploads
        * sets permissions for ~/uploads
        * dumps and restores database at ~/_sql
        * updates url references in database
    * `value: drupal6`
        * maintains drupal6 database config file ~/sites/default/settings.php
        * rsyncs git untracked ~/sites/default/files
        * sets permissions for ~/sites/default/files
        * invokes `drush updatedb`
        * dumps and restores database at ~/_sql
        * updates url references in database
        * resets drupal6 admin password
    * `value: drupal7`
        * maintains drupal7 database config file ~/sites/default/settings.php
        * rsyncs git untracked ~/sites/default/files
        * sets permissions for ~/sites/default/files
        * invokes `drush updatedb`
        * dumps and restores database at ~/_sql
        * updates url references in database
        * resets drupal7 admin password
    * `value: silverstripe`
        * maintains silverstripe database config file ~/mysite/_config.php
        * dumps and restores database at ~/_sql
        * updates url references in database
    * `value: wordpress`
        * maintains wordpress database config file ~/wp-config.php
        * rsyncs git untracked ~/wp-content/uploads
        * sets permissions for ~/wp-content/uploads
        * invokes `wp-cli core update-db`
        * dumps and restores database at ~/_sql
        * updates url references in database
        * resets wordpress admin password
    * `value: xenforo`
        * maintains xenForo database config file ~/library/config.php
        * rsyncs git untracked ~/data and ~/internal_data
        * sets permissions for ~/data and ~/internal_data
        * dumps and restores database at ~/_sql
        * updates url references in database
* software_dbprefix:
    * `dependency: software`
    * `required: false`
    * `default: null`
    * `example: wp_`
        * the value that prefixes table names within the database
            * PLEASE NOTE: table prefixes included in software distributions, such as WordPress' `wp_`, must be specified if desired
* software_workflow:
    * `dependency: software`
    * `required: true`
    * `value: downstream`
        * specifies Production as the source for the database and software file store
        * this option is useful for maintaining a website
    * `value: upstream`
        * specifies Test as the source for the database and software file store
        * this option is useful for launching a new website
        * PLEASE NOTE: affects the Production website instance - see [Release Management](#release-management)
* webroot:
    * `required: false`
    * `default: null`
    * `example: www/`
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash



## Website Development ##

Performing development in a local environment is critical to reducing risk by exacting the environments that exist upstream, accomplished with Vagrant and VirtualBox.

**Website Repositories**

* Repositories for websites are cloned into the Catapult instance at ~/repositories and in the respective apache or iis folder, listed by domain name.
    * Repositories are linked between the host and guest for realtime development.

**Working with Databases**

* Leverage Catapult's workflow model (configured by `software_workflow`) to trigger a database refresh. From the develop branch, commit a deletion of today's database backup from the ~/_sql folder.

**Forcing www**

* Forcing www is software specific, unlike forcing the https protocol, which is environment specific and driven by the `force_https` option. To force www ([why force www?](http://www.yes-www.org/)), please follow the respective guides per software:
    * `value: codeigniter2`
        * `~/.htaccess` no official documentation - http://stackoverflow.com/a/4958847/4838803
    * `value: codeigniter3`
        * `~/.htaccess` no official documentation - http://stackoverflow.com/a/4958847/4838803
    * `value: drupal6`
        * `~/.htaccess` https://github.com/drupal/drupal/blob/6.x-18-security/.htaccess#L87
    * `value: drupal7`
        * `~/.htaccess` https://github.com/drupal/drupal/blob/7.x/.htaccess#L89
    * `value: silverstripe`
        * `~/mysite/_config.php` no official documentation - http://www.ssbits.com/snippets/2010/a-config-php-cheatsheet/
    * `value: wordpress`
        * http://codex.wordpress.org/Changing_The_Site_URL
    * `value: xenforo`
        * `~/.htaccess` no official documentation - http://stackoverflow.com/a/4958847/4838803



## Performance Testing ##

Often disregarded, performance testing is a crucial component of quality assurance. The risks of neglecting performance testing include downtime, SEO impacts, gaps in analytics, poor user experience, and unknown ability to scale.

With Catapult's exactly duplicated configuration, even the Test environment can accurately represent the performance potential of the Production environment. [ApacheBench](https://httpd.apache.org/docs/2.4/programs/ab.html) is a powerful tool to test request performance and concurrency - OSX includes ApacheBench out of the box, while [this StackOverflow post](http://stackoverflow.com/a/7407602/4838803) details how to get up and running on Windows.

ApacheBench enables us to profile request performance (`-n` represents the number of requests to perform) and concurrency (`-c` represents the number of multiple requests to make at a time) to test for performance, including common limits such as [C10k and C10M](http://highscalability.com/blog/2013/5/13/the-secret-to-10-million-concurrent-connections-the-kernel-i.html).

### Website Concurrency Maxiumum ###

Using a website with historical Google Analytics data, access the Audience Overview and find the busiest Pageview day from the past 30-days and then drill into that date. Find the hour with the most Pageviews, then the accompanying Avg. Session Duration. Using the following formula, we are able to find the Concurrency Maxiumum.

*(Pageviews x Avg. Session Duration - in seconds) / 3,600 seconds* = **Concurrency Maxiumum**

Take a website with an average of 500 pageviews per hour, or 365,000 pageviews per month, which has a busiest hour of 1,000 pageviews.

Pageviews | Avg. Session Duration | Total Session Seconds | Concurrency Maxiumum
----------|-----------------------|-----------------------|---------------------
1,000 | 60 minutes (3,600 seconds) | 3,600,000 | **1,000**
1,000 | 10 minutes (600 seconds) | 600,000 | **166**
1,000 | 5 minutes (300 seconds) | 300,000 | **88**
1,000 | 1 minute (60 seconds) | 60,000 | **16**

**100 concurrent requests performed 10 times**
````
ab -l -r -n 1000 -c 100 -H "Accept-Encoding: gzip, deflate" http://test.devopsgroup.io/
````

Take a website with an average of 20 pageviews per hour, or 14,600 pageviews per month, which has a busiest hour of 100 pageviews.

Pageviews | Avg. Session Duration | Total Session Seconds | Concurrency Maxiumum
----------|-----------------------|-----------------------|---------------------
100 | 60 minutes (3,600 seconds) | 36,000 | **1,000**
100 | 10 minutes (600 seconds) | 60,000 | **16**
100 | 5 minutes (300 seconds) | 30,000 | **8**
100 | 1 minute (60 seconds) | 6,000 | **1.6**

**10 concurrent requests performed 10 times**
````
ab -l -r -n 100 -c 10 -H "Accept-Encoding: gzip, deflate" http://test.devopsgroup.io/
````

### Interpreting Apache AB Results ###

Using a satisifed [Apdex](https://en.wikipedia.org/wiki/Apdex) of 7 seconds, we can see that 98% of users would be satisfied.

````
Percentage of the requests served within a certain time (ms)
  50%     19
  66%     21
  75%     24
  80%     27
  90%     34
  95%   3968
  98%   6127
  99%   7227
 100%   7325 (longest request)
````



## Disaster Recovery ##

Being able to react to disasters immediately and consistently is crucial - Catapult affords you fast rebuilding and rollbacks.



### Server Rebuilding ###

* LocalDev is rebuildable by running `vagrant destroy` then `vagrant up` for the respective virtual machine.
* Test, QC, and Production are rebuildable by running `vagrant rebuild` for the respective virtual machine - this is necessary (rather than a destroy and up) to retain the IP addresses of the machine.



### Website Rollbacks ###

**Production Website Rollbacks:**

* `software_workflow: upstream`
    * Files
        * Reverse the offending merge commit from the master branch and run the Production deployment.
    * Database
        * Reverse the offending merge commit from the master branch and run the Production deployment.
        * Note: The Production database is overwritten and restored from the latest sql dump file from Test in the ~/_sql folder.
* `software_workflow: downstream`
    * Files
        * Reverse the offending merge commit from the master branch and run the Production deployment.
    * Database
        * Reverse the offending database dump auto-commit from the develop branch and manually restore the Production database from the desired sql dump file in the ~/_sql folder.
        * Note: The Production database is dumped once per day when the production build is run.


# Troubleshooting #

Below is a log of service related troubleshooting. If you're having issues related to Catapult, [submit a GitHub Issue](https://github.com/devopsgroup-io/catapult/issues/new).

* **DigitalOcean**
    * [09-01-2015] vagrant rebuild was failing with a `The configured shell (config.ssh.shell) is invalid and unable to properly execute commands.` it is due to DigitalOcean's API not re-inserting the SSH key that was originally used during the first vagrant up (creation of the droplet). To rebuild, you must use the DigitalOcean console, run through the first root password reset workflow that was emailed to you, then vi /etc/sudoers and remove the `Defaults requiretty` line and save and exit. You can then run vagrant provision successfully.
* **GitHub**
    * [09-08-2015] Some database dumps exceed 100MB, so it's recommened to use Bitbucket in those instances as Catapult auto-commits database dumps to your website's repository, up to 500MB worth of database dumps or the one, newest database dump. [Bitbucket](https://help.github.com/articles/what-is-my-disk-quota/) has a 2GB hard repo push limit with no documented file limit and [GitHub](https://help.github.com/articles/what-is-my-disk-quota/) has a 1GB soft repo limit with a 100MB file size limit.
* **Vagrant**
   * [02-04-2015] When upgrading Vagrant you may run into errors - the most common issue are mismatched plugins, running this command has a good chance of success `sudo rm -Rf ~/.vagrant.d/gems/ && sudo rm ~/.vagrant.d/plugins.json`


# Contributing #

Here are some ways which we welcome you to contribute to Catapult:

  * Submit a pull request
  * Report an issue
  * Provide feedback on open issues
  * Improve documentation in the README
  * Share your experiences with Catapult

When you first setup Catapult, a `develop-catapult` branch is created for you under your forked repository with the git remote upstream set to `https://github.com/devopsgroup-io/catapult.git` so that you can easily create a pull request. Also keep in mind when closing issues to submit a pull request that includes [GitHub's: Closing issues via commit messages](https://help.github.com/articles/closing-issues-via-commit-messages/).



## Releases ##

Releases are driven by the devopsgroup.io team and occur when accepting new pull requests from contributors like you. Releases follow [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html). Given a version number MAJOR.MINOR.PATCH, increment the:

* MAJOR version when you make incompatible API changes,
* MINOR version when you add functionality in a backwards-compatible manner, and
* PATCH version when you make backwards-compatible bug fixes.

In addition, the release version number will be prefaced with a `v` (v1.0.0) to conform to standard practice.

As part of a new release, the version number in VERSION.yml will be incremented and git tagged with the same version number along with a [GitHub Release](https://help.github.com/articles/about-releases/).



# Community #



## Partnerships ##

The Catapult team values partnerships and continuous improvement.

* [01-28-2016] Pantheon provides feedback
* [01-22-2016] New Relic provides private beta access to their Synthetics API along side Breather, Carfax, Ring Central, Rackspace, and IBM.



## Conferences ##

Catapult is making the conference tour! We plan to attend the following conferences, with more to come. Get a chance to see Catapult in action, presented by it's core developers.

* Spring 2016 [04-08-2016] [Drupaldelphia](http://drupaldelphia.com/)
* Summer 2016 [Wharton Web Conference](http://www.sas.upenn.edu/wwc/)
* Winter 2016 [WordCamp US](http://us.wordcamp.org/)



## Local Events ##

Catapult will also be seen throughout local meetups in the Philadelphia and Greater Philadelphia area! Get a chance to meet the team and engage at a personal level.

* [Philly Tech Meetup](http://www.meetup.com/philly-tech/) 4k+ technologists
* [Princeton Tech ](http://www.meetup.com/Princeton-Tech/) 3.5k+ technologists
* [Technical.ly Philly](http://www.meetup.com/Technically-Philly/) 3k+ technologists
* [Philadelphia WordPress Meetup Group](http://www.meetup.com/philadelphia-wordpress-meetup-group/) 1.5k+ technologists
* [Philly DevOps](http://www.meetup.com/PhillyDevOps/) 700+ technologists
* [Greater Philadelphia Drupal Meetup Group](http://www.meetup.com/drupaldelphia/) 500+ technologists



# References #
1. Atlassian. Comparing Workflows. https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow. Accessed February 15, 2016.
2. Pantheon. Load and Performance Testing: Before You Begin. https://pantheon.io/docs/articles/load-and-performance-testing/. Accessed February 20, 2016.
3. Acquia. Acquia Dev Desktop. https://www.acquia.com/products-services/dev-desktop. Accessed February 20, 2016.
