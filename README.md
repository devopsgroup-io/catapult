# Release Management #

Copyright (c) 2015 devopsgroup.io - Seth Reeser

Welcome to Release Management; the pre-configured, full-stack, development, test, qc, and production environments.

## Setup ##

Release Management uses several APIs to pull everything off - below is a list of the required accounts and setup steps. All of the configuration is placed in configuration.yml, which is initialized from configuration.yml.example

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

## Usage ##

Release Management is centered around web and database servers. The web and database servers are provisioned (created) via Vagrant and automatically continuously integrated (when new code is detected) via Bamboo.
