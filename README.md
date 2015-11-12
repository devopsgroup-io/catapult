# Catapult Release Management #



**Welcome to devopsgroup.io Catapult Release Management**, a complete DevOps Release Management solution featuring automated website deployment and continuous integration, while following Gitflow and SCRUM workflows. Built for Developers, but simple enough to use by non-Developers. Catapult's core technologies and features include:

* Configuration Management via CloudFlare, DigitalOcean, Git, GPG, Shell, and Vagrant
* Continuous Integration via Bamboo and AWS
* Source Code Management via Bitbucket and/or GitHub
* Website Uptime Monitoring via monitor.us (Monitis)


As a **non-Developer** you may think - *I already have a website, why do I need Catapult?* Over time you may find yourself overwhelmed with managing the the day to day DevOps process of infrastrucrure , and end up paying a freelancer or a development company hundreds or even thousands of dollars to manage or interact with the DevOps (Development Operations) to solve these problems:

  * Production is down.
  * We need a test site.
  * Why is this costing so much?
  * Are my environments safe? 
  * Is my website backed up?
  * Can I easily scale my website for more traffic?
  * What is my uptime?

As a **Developer**, you have to manage many websites and probably end up using the same set of tools and APIs over and over again. Why not use something that has been created from it's foundations by Devlopers that have been down the same road as you, and contribute back to the project at the same time?

  * Catapult is developed in Ruby and native Shell - there are no new languages or technologies to learn.
  * Catapult's simplicity is it's strength. There is no black-box to decipher - the functionality and methodology is out in the open and accessible to anyone.
  * Catapult uses the most popular APIs and services; including AWS, Bamboo, Bitbucket, CloudFlare, DigitalOcean, GitHub, and Vagrant.

Catapult manages all of this for you through an open-source and well-documented platform, with a developer-focused point of view. We also provide a service and assistance if you need help getting started, or just have a question - just contact us at https://devopsgroup.io. Catapult leverages the Services that you're already using, which collectively, costs $40/month to have a full-stack localDev, Test, Quality Control, and Production environment.

*Go ahead, give* **Catapult** *a* **shot**.



## Table of Contents ##

- [Catapult Release Management](#catapult-release-management)
    - [Table of Contents](#table-of-contents)
    - [Supported Software](#supported-software)
- [Setup](#setup)
    - [Developer Setup](#developer-setup)
    - [Instance Setup](#instance-setup)
    - [Services Setup](#services-setup)
- [Usage](#usage)
    - [Provision Environments](#provision-environments)
    - [Configure Automated Deployments](#configure-automated-deployments)
    - [Provision Websites](#provision-websites)
    - [Develop Websites](#develop-websites)
- [Troubleshooting](#troubleshooting)
- [Services Justification](#services-justification)
- [Contributing](#contributing)
    - [Releases](#releases)
- [Community](#community)



## Supported Software ##

Catapult supports the following software:

* Any website without a database dependency built in PHP
* CodeIgniter 2.x
* CodeIgniter 3.x
* Drupal 6.x, Drupal 7.x
    * as required by Drush 7.0.0
* SilverStripe 2.x
* WordPress 3.5.2+, WordPress 4.x
    * as required by WP-CLI
* XenForo 1.x



# Setup #

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
    1. Fork https://github.com/devopsgroup-io/catapult-release-management and clone via SourceTree or the git utility of your choice.
2. **Vagrant Plugins**
    1. Open your command line and cd into the newly cloned repository and install the following Vagrant plugins.
        1. `vagrant plugin install vagrant-digitalocean` [GitHub](https://github.com/smdahlen/vagrant-digitalocean), [RubyGems](https://rubygems.org/gems/vagrant-digitalocean)
        2. `vagrant plugin install vagrant-hostmanager` [GitHub](https://github.com/smdahlen/vagrant-hostmanager), [RubyGems](https://rubygems.org/gems/vagrant-hostmanager)
        3. `vagrant plugin install vagrant-vbguest` [GitHub](https://github.com/dotless-de/vagrant-vbguest), [RubyGems](https://rubygems.org/gems/vagrant-vbguest)
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

1. **Hosting:**    
    1. **DigitalOcean** sign-up and configuration
        1. Create an account at http://digitalocean.com
           * Get a $10 credit and give us $25 once you spend $25 https://www.digitalocean.com/?refcode=6127912f3462
        2. Create a Personal Access Token at https://cloud.digitalocean.com/settings/applications named "Vagrant" and place the token value at `~/secrets/configuration.yml["company"]["digitalocean_personal_access_token"]`
        3. Add your newly created id_rsa.pub from ~/secrets/id_rsa.pub key in https://cloud.digitalocean.com/settings/security named "Vagrant"
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
    1. **Amazon Web Services** (AWS) EC2 sign-up and configuration (Required for Bamboo)
        1. Create an AWS account https://portal.aws.amazon.com/gp/aws/developer/registration
        2. Sign in to your new AWS console https://console.aws.amazon.com
        3. Go to your AWS Identity and Access Management (IAM) Users Dashboard https://console.aws.amazon.com/iam/home#users
            1. Create a "Bamboo" user.
            2. **Please note both the Access Key ID and Secret Access Key.**
        4. Go to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Create a "Bamboo" group.
            2. Attach the "AmazonEC2FullAccess" policy to the "Bamboo" group.
        5. Go back to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
            1. Select your newly created "Bamboo" group.
            2. Select Add Users to Group and add your newly created "Bamboo" user.
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
                    1. Set your AWS EC2 "Bamboo" Access Key ID and Secret Access Key
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
    1. **monitor.us** sign-up and configuration
        1. Create a monitor.us account at http://www.monitor.us
        2. Sign in to your new monitor.us account
        3. Go to Tools > API > API Key.
        4. Place your API key at `~/secrets/configuration.yml["company"]["monitorus_api_key"]`
        5. Place your Secret key at `~/secrets/configuration.yml["company"]["monitorus_secret_key"]`
6. **Verify Configuration:**    
    1. To verify all of the configuration that you just set, open your command line and cd into your fork of Catapult, then run `vagrant status`. Catapult will confirm connection to all of the Services and inform you of any problems.

| Service                       | Description                                                      | Monthly Cost |
|-------------------------------|------------------------------------------------------------------|-------------:|
| **Hosting:**                  |                                                                  |              |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-test-redhat`             | $5           |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-qc-redhat`               | $5           |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-production-redhat`       | $5           |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-test-redhat-mysql`       | $5           |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-qc-redhat-mysql`         | $5           |
| DigitalOcean                  | `~/secrets/configuration.yml["company"]["name"]-production-redhat-mysql` | $5           |
| **Repositories:**             |                                                                  |              |
| Bitbucket                     | Private Repositories                                             | Free         |
| GitHub                        | Public Repositories                                              | Free         |
| **Automated Deployments:**    |                                                                  |              |
| Amazon Web Services           | Build Server                                                     | $1 - $15     |
| Bamboo                        | Continuous Integration                                           | $10          |
| **DNS:**                      |                                                                  |              |
| CloudFlare                    | test., qc., and production global DNS                            | Free         |
| **Monitoring:**               |                                                                  |              |
| monitor.us                    | Production website updtime monitoring                            | Free         |
| **Total**                     |                                                                  | $41 - $55    |



# Usage #

To use Catapult you will need to [Provision Environments](#provision-environments), [Configure Automated Deployments](#configure-automated-deployments), then [Provision Websites](#provision-websites).



## Provision Environments ##

| Environment                   | dev                                                         | test                                                          | qc                                                            | production                                                    |
|-------------------------------|-------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|
| **Server Provider**           | Locally via VirtualBox                                      | Hosted via DigitalOcean                                       | Hosted via DigitalOcean                                       | Hosted via DigitalOcean                                       |
| **Server Provisioning**       | Manually via Vagrant                                        | Manually via Vagrant                                          | Manually via Vagrant                                          | Manually via Vagrant                                          |

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
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "test" "https://github.com/[your-name-here]/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["test"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "test" "https://github.com/[your-name-here]/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
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
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "qc" "https://github.com/[your-name-here]/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["qc"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "qc" "https://github.com/[your-name-here]/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
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
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "production" "https://github.com/[your-name-here]/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "apache"`
            7. Click Save
        5. Click Add task
            1. Search for SSH Task and select it
            2. Host: `~/secrets/configuration.yml["environments"]["production"]["servers"]["redhat_mysql"]["ip"]`
            3. Username: `root`
            4. Authentication Type: `Key without passphrase`
            5. SSH Key: `~/secrets/id_rsa`
            6. SSH command: `bash /catapult/provisioners/redhat/provision.sh "production" "https://github.com/your-name-here/catapult-release-management" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mysql"`
            7. Click Save



## Provision Websites ##

Adding websites to Catapult is easy. The only requirement is that the website needs to be contained in its own repo on GitHub or Bitbucket. Websites are then added to configuration.yml, a minimal addition looks like this:

```
websites:
  apache:
  - domain: devopsgroup.io
    repo: git@github.com:devopsgroup-io/devopsgroup-io.git
```

The following options are available:

* domain:
    * `example.com`
        * the domain name of what the website is/will be in production
        * a maximum of one subdomain is supported (subdomain.example.com)
        * this drives the domains of localdev (via hosts file) and test, qc, production (via cloudflare)
        * dev.example.com, test.example.com, qc.example.com, example.com
* domain_tld_override:
    * `mycompany.com`
        * a domain name that will override the tld of the domain for when you do not have control of the domain (example.com), but still need a localdev and externally accessible test and qc instance
        * this drives the domains of localdev (via hosts file) and test, qc, production (via cloudflare)
            * to seamlessly cutover to example.com, remove this option
        * dev.example.com, test.example.com, qc.example.com, example.com are replaced by dev.example.com.mycompany.com, test.example.com.mycompany.com, qc.example.com.mycompany.com, example.com.mycompany.com
* force_auth:
    * `example`
        * forces http basic authentication in test, qc, and production
        * `example` is both the username and password
* force_auth_exclude:
    * `["test","qc","production"]`
        * array of exclusions exclusive to the force_auth option
* force_https:
    * `true`
        * rewrite all http traffic to https
* repo:
    * `git@github.com:devopsgroup-io/devopsgroup-io.git`
        * GitHub and Bitbucket over SSH are supported, HTTPS is not supported
* software:
    * `codeigniter2`
        * generates codeigniter2 database config file ~/application/config/database.php, restores database
    * `codeigniter3`
        * generates codeigniter3 database config file ~/application/config/database.php, restores database
    * `drupal6`
        * generates drupal6 database config file ~/sites/default/settings.php, resets Drupal admin password, rsyncs ~/sites/default/files, restores database
    * `drupal7`
        * generates drupal7 database config file ~/sites/default/settings.php, resets Drupal admin password, rsyncs ~/sites/default/files, restores database
    * `silverstripe`
        * generates silverstripe database config file ~/mysite/_config.php, restores database
    * `wordpress`
        * generates WordPress database config file ~/installers/wp-config.php, resets WordPress admin password, rsyncs ~/wp-content/uploads, restores database
    * `xenforo`
        * generates xenforo database config file ~/library/config.php, restores database
* software_dbprefix:
    * `wp_`
        * usually used in Drupal for multisite installations (`wp_` is required for base Wordpress installs, Drupal has no prefix by default)
* software_workflow:
    * `downstream`
        * production is the source for the database and upload directories of drupal and wordpress
        * this option is used when maintaining a website
        * see the below chart for more details
    * `upstream`
        * test is the source for the database and upload directories of drupal and wordpress
        * this option is used when launching a new website
        * see the below chart for more details
* webroot:
    * `www/`
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash

Once you add a new website to configuration.yml, it's time to test in localdev:

  * `vagrant provision ~/secrets/configuration.yml["company"]["name"]-dev-redhat`
  * `vagrant provision ~/secrets/configuration.yml["company"]["name"]-dev-redhat-mysql`

Once you're satisfied with new website in localdev, it's time to commit configuration.yml.gpg to your Catapult fork's develop branch, this will kick off a automated deployment of test. Once you're satisfied with the website in test, it's time to create a pull request from your Catapult fork's develop branch into release - once the pull request is merged, this will kick off an automated deployment to qc. Once you're satisfied with the website in qc, it's time to create a pull request from your Catapult fork's release branch into master. Production does not have any automated deployments, to deploy your website to production it's time to login to Bamboo and press the deployment button for production.

Once a website exists in the upstream environments (test, qc, production), automated deployments will kick off if changes are detected on their respected branches (see chart below). The same workflow of moving a website upstream, exists when you make changes to a specific website's repository.

| Environment                    | dev                                                         | test                                                            | qc                                                             | production                                                    |
|--------------------------------|-------------------------------------------------------------|-----------------------------------------------------------------|----------------------------------------------------------------|---------------------------------------------------------------|
| **Running Branch**             | *develop*                                                   | *develop*                                                       | *release*                                                      | *master*                                                      |
| **New Website Provisioning**   | Manually via Vagrant                                        | Automatically via Bamboo (new commits to **develop**)           | Automatically via Bamboo (new commits to **release**)          | Manually via Bamboo                                           |
| **Downstream Database**        | Restore from **develop** ~/_sql folder of website repo      | Restore from **develop** ~/_sql folder of website repo          | Restore from **master** ~/_sql folder of website repo          | Daily backup to **develop** ~/_sql folder of website repo     |
| **Upstream Database**          | Restore from **develop** ~/_sql folder of website repo      | Daily backup to **develop** ~/_sql folder of website repo       | Restore from **master** ~/_sql folder of website repo          | Restore from **master** ~/_sql folder of website repo         |
| **Downstream Untracked Files** | rsync files from **production**                             | rsync files from **production**                                 | rsync files from **production**                                | --                                                            |
| **Upstream Untracked Files**   | rsync files from **test**                                   | --                                                              | rsync files from **test**                                      | rsync files from **test**                                     |
| **Automated Deployments**      | Manually via `vagrant provision`                            | Automatically via Bamboo (new commits to **develop**)           | Automatically via Bamboo (new commits to **release**)          | Manually via Bamboo                                           |



## Develop Websites ##

Once you Provision Websites and it's time to work on a website, there are a few things to consider:

* Using the `software_workflow` flag for `upstream` websites is great, you can develop your code in localDev then have anyone in your company enter content into Drupal, Wordpress, etc. However, in the cercumstance that you absolutely need to move your localDev database `upstream`, it's as easy as saving a .sql dump to your website's repository develop branch under the _sql folder with today's date (following the YYYYMMDD.sql format). You can then `vagrant rebuild` the `~/secrets/configuration.yml["company"]["name"]-test-redhat-mysql` server and it will restore from your new sql dump.




# Troubleshooting #

Below is a list of known limitations with Catapult, if you're still having issues with Catapult, [submit a GitHub Issue](https://github.com/devopsgroup-io/catapult-release-management/issues/new).

* **CloudFlare**
    * [07-27-2015] If your `~/secrets/configuration.yml["websites"]["apache/iis"]["domain"]` is a subdomain (drupal7.devopsgroup.io) the `force_https` option will only work in localdev and production as CloudFlare only supports a first-level subdomain. https://www.cloudflare.com/ssl
* **DigitalOcean**
    * [09-01-2015] vagrant rebuild was failing with a `The configured shell (config.ssh.shell) is invalid and unable to properly execute commands.` it is due to DigitalOcean's API not re-inserting the SSH key that was originally used during the first vagrant up (creation of the droplet). To rebuild, you must use the DigitalOcean console, run through the first root password reset workflow that was emailed to you, then vi /etc/sudoers and remove the Defaults requiretty line and save and exit. You can then run vagrant provision successfully.
* **Git**
    * [09-08-2015] Some database dumps exceed 100MB, so it's recommened to use Bitbucket in those instances as Catapult auto-commits database dumps to your website's repository, up to 500MB worth of database dumps or the one, newest database dump. [Bitbucket](https://help.github.com/articles/what-is-my-disk-quota/) has a 2GB hard repo push limit with no documented file limit and [GitHub](https://help.github.com/articles/what-is-my-disk-quota/) has a 1GB soft repo limit with a 100MB file size limit.
* **monitor.us**
    * [08-10-2015] If your `~/secrets/configuration.yml["websites"]["apache/iis"]["domain"]` includes the `force_https` option, you will need to login to monitor.us and enable SNI from Monitors > Monitor List > Actions > Basic Settings > Enable SNI support. 
* **Vagrant**
    * [07-27-2015] If your `~/secrets/configuration.yml["websites"]["apache/iis"]["domain"]` includes the `force_https` option, during `vagrant status` you will receive an err for the http response code for `.dev` as this is a self-signed cert and not routing through CloudFlare.



# Services Justification #

Catapult uses many factors to make the best decision when it comes to choosing **Services**, the following are taken into account - popularity, cost, API support, and user experience. The following is an outline of what we think the common questions may be when you see Catapult using a particular **Service**. Have your own perspective? [Let us know](https://github.com/devopsgroup-io/catapult-release-management/issues/new).

* **monitor.us**
    * [08-10-2015] monitor.us does not have the greatest user interface, branding, or technology. However, it does something that no other application monitoring services do - it offers free http/https monitoring and an API that allows Catapult to add these monitors for you.
        * A service to watch would be New Relic, however, the blocker is that there is no API support for their synthetic monitoring.
        * Other services researched were AppDynamics, DataDog, and StatusCake which all fell short in pricing or API functionality.



# Contributing #

So you want to contribute... Great! Open source projects like Catapult Release Management succeed or fail upon the involvement of a thriving community of developers, who often offer various levels of code skills and time commitment. Here are some ways you can begin contributing right away, at whatever level is most comfortable for you.

  * Submit a feature
  * Report a bug
  * Verify and track down a reported bug
  * Add documentation to the README
  * Answer project specific questions
  * Contribute to the Catapult wiki
  * Blog about your experiences with Catapult

When you first setup Catapult a `develop-catapult` branch is created for you under your forked repository, with an upstream set to `https://github.com/devopsgroup-io/catapult-release-management.git` so that you can easily create a pull request. Also keep in mind when closing issues to submit a pull request that includes [GitHub's: Closing issues via commit messages](https://help.github.com/articles/closing-issues-via-commit-messages/).



## Releases ##

Releases are driven by the devopsgroup.io team and occur when accepting new pull requests from contributors like you. Releases follow Semantic Versioning 2.0.0, given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards-compatible manner, and
3. PATCH version when you make backwards-compatible bug fixes.

In addition, the release will be prefaced with a `v` (v1.0.0) to conform standard practice.

During a new release, the version number in VERSION.yml will be incremented and tagged with the same version number along with a [GitHub Release](https://help.github.com/articles/about-releases/).

See http://semver.org/spec/v2.0.0.html for more information.



# Community #



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
