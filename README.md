# devopsgroup.io Release Management #

Copyright (c) 2015 devopsgroup.io - Seth Reeser

Welcome to devopsgroup.io Release Management; the pre-configured, full-stack, development, test, quality control, and production environments.

## Services Setup ##

devopsgroup.io Release Management uses several third-party services to pull everything off - below is a list of the required services and setup steps. All of the configuration is placed in configuration.yml, which is initialized from configuration.yml.example

1. DigitalOcean Sign-Up and Configuration
    1. Create an account at http://digitalocean.com
    2. Create a Personal Access Token at https://cloud.digitalocean.com/settings/applications named "Vagrant" and place the token value in ~/configuration.yml at ["company"]["digitalocean_personal_access_token"] 
    3. Create an SSH Key https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets and place in ~/provisioners/.ssh
    4. Add the newly created id_rsa.pub key in https://cloud.digitalocean.com/settings/security named "Vagrant"

3. Amazon Web Services (AWS) EC2 Sign-Up and Configuration (Required for Bamboo)
    1. Create an AWS account https://portal.aws.amazon.com/gp/aws/developer/registration
    2. Sign in to your new AWS console https://console.aws.amazon.com
    3. Go to your AWS Identity and Access Management (IAM) Users Dashboard https://console.aws.amazon.com/iam/home#users
        1. Create a "Bamboo" user.
        2. Please note both the Access Key ID and Secret Access Key.
    4. Go to your AWS Identity and Access Management (IAM) Groups Dashboard https://console.aws.amazon.com/iam/home#groups
        1. Create a "Bamboo" group.
        2. Attach the "AmazonEC2FullAccess" policy to the "Bamboo" group.

2. Atlassian Bamboo Sign-Up and Configuration
    1. Create a Bamboo Cloud account at https://www.atlassian.com/software/bamboo
    2. Sign in to your new custom Bamboo instance https://[your-name-here].atlassian.net
    3. Go to your Elastic Bamboo configuration https://[your-name-here].atlassian.net/builds/admin/elastic/editElasticConfig.action
        1. Set your AWS EC2 "Bamboo" Access Key ID and Secret Access Key

## Developer Setup ##

devopsgroup.io Release Management is controlled via Vagrant and the command line - below is a list of required software.

1. Vagrant
    1. Please download and install from https://www.vagrantup.com/downloads.html
2. VirtualBox
    1. Please download and install from https://www.virtualbox.org/wiki/Downloads
3. SourceTree
    1. Please download and install from https://www.sourcetreeapp.com/
4. Sublime Text 3
    1. Please download and install from http://www.sublimetext.com/3

## Usage ##

devopsgroup.io Release Management is centered around web and database servers. The web and database servers are provisioned (created) via Vagrant and continuously integrated (when new code is detected) via Bamboo. **Please Note:** It is advised to turn off any antivirus software that you may installed during Developer Setup and Usage of devopsgroup.io Release Management as necessary tasks such as forwarding ports and writing hosts files may be blocked.

1. Clone devopsgroup.io Release Management
    1. Clone https://github.com/devopsgroup-io/release-management via SourceTree or the git utility of your choice.
2. Once the devopsgroup.io Release Management repository is cloned, open your command line of choice and cd into the newly cloned ~/release-management repository (~ stands for your home folder, i.e. /Users/reeser/)
3. From here, you will need to install any of the required Vagrant plugins. To see these, run the vagrant status command and any Vagrant plugins that you do not have installed, will be displayed with the command to install.
