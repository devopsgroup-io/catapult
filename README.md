# devopsgroup.io Catapult Release Management #

Copyright (c) 2015 devopsgroup.io - Seth Reeser

Welcome to devopsgroup.io Catapult Release Management, a full stack software and workflow solution. Herein known as Catapult.

## Supported Software ##

Catapult currently supports the following software:

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

1. Vagrant
    1. Please download and install from https://www.vagrantup.com/downloads.html
2. VirtualBox
    1. Please download and install from https://www.virtualbox.org/wiki/Downloads
3. SourceTree
    1. Please download and install from https://www.sourcetreeapp.com/
4. Sublime Text 3
    1. Please download and install from http://www.sublimetext.com/3
5. GPG2
    * Using OSX ? Please download and install GPG Suite https://gpgtools.org
    1. Using Windows? Please download and install Gpg4win from http://gpg4win.org/download.html

## Instance Setup ##

Catapult is quick to setup. Fork the Github repository and start adding your configuration.

1. Fork https://github.com/devopsgroup-io/release-management and clone via SourceTree or the git utility of your choice.
2. Open your command line and cd into the newly cloned repository.
3. From here, you will need to install all of the required Vagrant plugins. To see these, run the vagrant status command and any Vagrant plugins that you do not have installed, will be displayed with the command to install.
4. Next, you will need to create and add your team's gpg_key to the untracked configuration-user.yml.
    1. NEVER SHARE THE GPG_KEY WITH ANYONE OTHER THAN YOUR TEAM.
    2. The gpg_key is the single key that encrypts all of your configuration for your instance.
    3. Spaces are not permitted and must be at least 20 characters.
    4. It is recommended to create and print a QR code of the gpg_key to distribute to your team.
    5. Remember; security is 99% process and 1% technology.
5. Next, you will need to configure gpg_edit mode so that during the Services Setup you can add your secrets to configuration.yml and commit your secrets to configuration.yml.gpg.
    1. To do so, set gpg_edit to true in configuration-user.yml.
    2. This will now allow you to add secrets to configuration.yml and run vagrant status to encrypt the secrets in configuration.yml.gpg

## Services Setup ##

Catapult uses several third-party services to pull everything off - below is a list of the required services and setup steps.

1. **Hosting:** DigitalOcean Sign-Up and Configuration
    1. Create an account at http://digitalocean.com
    2. Create a Personal Access Token at https://cloud.digitalocean.com/settings/applications named "Vagrant" and place the token value in ~/configuration.yml at ["company"]["digitalocean_personal_access_token"]
    3. Create an SSH Key https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets and place in ~/provisioners/.ssh
    4. Add the newly created id_rsa.pub key in https://cloud.digitalocean.com/settings/security named "Vagrant"

3. **Automated Deployments:** Amazon Web Services (AWS) EC2 Sign-Up and Configuration (Required for Bamboo)
    1. Create an AWS account https://portal.aws.amazon.com/gp/aws/developer/registration
    2. Sign in to your new AWS console https://console.aws.amazon.com
    3. Go to your AWS Identity and Access Management (IAM) Users Dashboard https://console.aws.amazon.com/iam/home#users
        1. Create a "Bamboo" user.
        2. Please note both the Access Key ID and Secret Access Key.
    4. Go to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
        1. Create a "Bamboo" group.
        2. Attach the "AmazonEC2FullAccess" policy to the "Bamboo" group.

4. **Automated Deployments:** Atlassian Bamboo Sign-Up and Configuration
    1. Create a Bamboo Cloud account at https://www.atlassian.com/software/bamboo
    2. Sign in to your new custom Bamboo instance https://[your-name-here].atlassian.net
    3. Go to your Elastic Bamboo configuration https://[your-name-here].atlassian.net/builds/admin/elastic/editElasticConfig.action
        1. Set your AWS EC2 "Bamboo" Access Key ID and Secret Access Key

5. **DNS:** [*Optional] CloudFlare
    * CloudFlare is optional, however, it provides two major components - free SSL certificate functionality (https) and DNS management - just update the name servers to clark.ns.cloudflare.com and liv.ns.cloudflare.com from the registrar where you purchased the domain name and Catapult will handle the rest.
    1. Create a CloudFlare account at https://www.cloudflare.com
    2. Sign in your new CloudFlare account
    3. Vist your My Account section at https://www.cloudflare.com/a/account/my-account and scroll down to your API Key and place the token value in ~/configuration.yml at ["company"]["cloudflare_api_key"]
    4. Place the email address of the email address that you used to sign up for CloudFlare at ["company"]["cloudflare_email"]

# Usage #

Catapult is centered around web and database servers. The web and database servers are provisioned (created) via Vagrant and continuously integrated (when new code is detected) via Bamboo.

## Adding Websites ##

Adding websites to devopsgroup.io is easy. Each website needs to be contained in its own repo on GitHub or Bitbucket. Websites are added to configuration.yml, a minimal addition looks like this:

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
        * generates codeigniter2 db config file ~/application/config/database.php, restores database
    * "drupal6"
        * generates drupal6 db config file ~/sites/default/settings.php, resets drupal6 admin password, rsyncs ~/sites/default/files from production source, restores database
    * "drupal7"
        * generates drupal7 db config file ~/sites/default/settings.php, resets drupal7 admin password, rsyncs ~/sites/default/files from production source, restores database
    * "wordpress"
        * generates wordpress db config file ~/installers/wp-config.php, resets wordpress admin password, rsyncs ~/wp-content/uploads from production source, restores database
* software_dbprefix:
    * "wp_"
        * usually used in drupal for multisite installations ("wp_ is required for base Wordpress installs, Drupal has no prefix by default")
* webroot:
    * "www"
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash

## Environments ##

|                      | DEV                                                         | TEST                                                        | QC                                                          | PRD                                                         |
|----------------------|-------------------------------------------------------------|-------------------------------------------------------------|-------------------------------------------------------------|-------------------------------------------------------------|
| **Running Branch**   | develop                                                     | develop                                                     | master                                                      | master                                                      |
| **Provisioning**     | Manually via Vagrant                                        | Automatically via Bamboo (watch for new commits to develop) | Automatically via Bamboo (watch for new commits to master)  | Manually via Bamboo                                         |
| **New Website**      | Restore from develop ~/_sql folder of website repo          | Daily backup to develop ~/_sql folder of website repo       | Restore from master ~/_sql folder of website repo           | Restore from master ~/_sql folder of website repo           |
| **Existing Website** | Restore from develop ~/_sql folder of website repo          | Restore from develop ~/_sql folder of website repo          | Restore from master ~/_sql folder of website repo           | Daily backup to develop ~/_sql folder of website repo       |

## Syncing Your Fork ##

To keep your fork updated with the latest from Catapult, please do the following.

1. git remote add upstream https://github.com/devopsgroup-io/release-management.git
2. git fetch upstream
3. git pull upstream master

# Contributing #

The open source community is an awesome thing, we hope Catapult is of use to you, and if you develop a feature that you think would benefit everyone, please submit a pull request.

## Versioning ##

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards-compatible manner, and
3. PATCH version when you make backwards-compatible bug fixes.

See http://semver.org/ for more information.
