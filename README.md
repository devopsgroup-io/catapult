# Release Management #

Copyright (c) 2015 devopsgroup.io - Seth Reeser

Welcome to Release Management; the pre-configured, full-stack, development, test, qc, and production environments.

## Setup ##

Release Management uses several APIs to pull everything off - below is a list of the required accounts and setup steps. All of the configuration is placed in configuration.yml, which is initialized from configuration.yml.example

1. DigitalOcean
    1. Create an account at http://digitalocean.com/
    2. Create a Personal Access Token at https://cloud.digitalocean.com/settings/applications named "Vagrant" and place the token value in ~/configuration.yml at ["company"]["digitalocean_personal_access_token"] 
    3. Create an SSH Key https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets and place in ~/provisioners/.ssh
    4. Add the newly created id_rsa.pub key in https://cloud.digitalocean.com/settings/security named "Vagrant"

2. 
