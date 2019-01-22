# Catapult #
<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/repositories/apache/_default_/svg/catapult.svg" alt="Catapult" width="200">

Catapult defines a best-practice infrastructure so you don't have to - it also aligns with Agile methodologies, like Scrum, to afford you everything you need to develop, deploy, and maintain a website with ease.

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_infrastructure.png" alt="Catapult Infrastructure">

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

* Catapult is an open source, complete, and distributed architecture
* Catapult only orchestrates - it is not required to run your infrastructure
* Catapult uses platform native shell scripting rather than configuration management tools such as Chef, Puppet, or Salt
* Catapult features Gitflow workflow while enforcing exactly matching, branch-driven environments
* Catapult features a unique software workflow model - upstream or downstream
* Catapult overlays seamlessly with Scrum methodology
* Catapult is very cost effective

*Go ahead, give* **Catapult** *a* **shot**.



## Security Disclosure ##

Security is very important to us. If you have any issue regarding security, please disclose the information responsibly by sending an email to security@devopsgroup.io and not by creating a GitHub issue.



## Platform Overview ##

Catapult orchestrates the following key components of DevOps to provide you with a full-featured infrastructure. Implementing both a Red Hat stack for PHP software and a Windows stack for .NET software.

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_platform_topology.png" alt="Catapult Platform Topology">

* **Security Management**
    * Configuration Secrets - GnuPG Encryption
* **Source Code Management**
    * Catapult - Git (via GitHub)
    * Websites - Git (via GitHub or Bitbucket)
* **Environment Management**
    * Vagrant
* **Environment Virtualization**
    * **Local**
        * VirtualBox - Red Hat and Windows
    * **Cloud**
        * DigitalOcean - Red Hat
        * Amazon Web Services (AWS) - Windows
* **DNS Management**
    * **Local**
        * vagrant-hostmanager
    * **Cloud**
        * CloudFlare
* **Release Management**
    * Automated Deployments - Atlassian Bamboo Server
    * Continuous Integration - Branch-based environments with Git triggers
* **Monitoring and Performance**
    * Server Resources - New Relic Servers
    * Application Performance - New Relic APM
    * Browser Performance - New Relic Browsers
    * Website Availability - New Relic Synthetics



## Supported Website Software ##

Catapult intelligently manages the following website software that have been chosen from trending usage statistics from [BuiltWith](https://trends.builtwith.com/cms) and aligns with the [CentOS 7](http://mirror.centos.org/centos/7/os/x86_64/Packages/) and [Software Collections](https://www.softwarecollections.org/) trunks:

Software | [Key](#websites) | Required PHP Version | Running PHP Version | Released | End-of-Life
---------|------------------|---------------------|---------------------|----------|------------
CodeIgniter 2                     | `codeigniter2`         | 5.1.6  | 5.4 | January 28, 2011   | [October 31, 2015](http://forum.codeigniter.com/thread-61357.html)
CodeIgniter 3                     | `codeigniter3`         | 5.6    | 7.1 | March 30, 2015     |
concrete5 8                       | `concrete58`           | 5.5.9  | 7.1 | December 1, 2016   |
Drupal 6                          | `drupal6`              | 5.4    | 5.4 | February 13, 2008  | [February 24, 2016](https://www.drupal.org/drupal-6-eol)
Drupal 7                          | `drupal7`              | 5.2.5  | 7.1 | January 5, 2011    |
Drupal 8                          | `drupal8`              | 5.5.9  | 7.1 | November 19, 2015  |
Elgg 1                            | `elgg1`                | 5.4    | 5.4 | August 20, 2008    |
Elgg 2                            | `elgg2`                | 5.6    | 7.1 | December 14, 2015  |
ExpressionEngine 3                | `expressionengine3`    | 5.3.10 | 5.4 | October 13, 2015   | [December 14, 2018](https://expressionengine.com/blog/version-3-end-of-life)
Joomla 3                          | `joomla3`              | 5.3.10 | 7.1 | September 27, 2012 |
Laravel 5                         | `laravel5`             | 7.0.0  | 7.1 | February 4, 2015   |
MediaWiki 1                       | `mediawiki1`           | 5.5.9  | 7.1 | December 8, 2003   |
Moodle 3                          | `moodle3`              | 5.6.5  | 7.1 | November 16, 2015  |
SilverStripe 3                    | `silverstripe3`        | 5.3.3  | 5.4 | June 29, 2012      |
SuiteCRM 7                        | `suitecrm7`            | 5.5    | 7.1 | October 21, 2013   | [November 15, 2019](http://support.sugarcrm.com/Resources/Supported_Versions/)
WordPress 4                       | `wordpress4`           | 5.2.4  | 7.1 | September 4, 2014  |
WordPress 5                       | `wordpress5`           | 5.2.4  | 7.1 | December 6, 2018   |
XenForo 1                         | `xenforo1`             | 5.2.11 | 5.4 | March 8, 2011      | [December 31, 2019](https://xenforo.com/community/threads/xenforo-1-5-end-of-life-schedule.157679/)
XenForo 2                         | `xenforo2`             | 5.4.0  | 7.1 | November 28, 2017  |
Zend Framework 2                  | `zendframework2`       | 5.3.23 | 5.4 | September 5, 2012  |

If you do not see your website software listed, Catapult supports basic PHP projects that do not have a database requirement.

* When an above software type is not defined, the default PHP version that is used is PHP 5.4. This is not configurable.
* PHP-less static site generators, such as, [Jekyll](https://jekyllrb.com/), are supported.

### PHP Versions ###

Catapult maintains a high level of integrity when it comes to PHP versions, through maintaining security, backwards compatibility, performance, and new features. Below is an overview of the PHP versions used in Catapult and when you can expect these versions to be End-of-Life (EOL). We will bump to the next highest version of PHP in the list when nearing the EOL - this provides ample time for support of the newer PHP version by the software. In cases where a software version is sunsetting, the CentOS Long-term Support (LTS) version of PHP is used.

PHP Version | End-of-Life | Maintainer | Updater
------------|-------------|------------|--------
5.4 | June 30, 2024 | [CentOS](https://wiki.centos.org/FAQ/General#head-fe8a0be91ee3e7dea812e8694491e1dde5b75e6d) | [RedHat](https://access.redhat.com/security/updates/backporting)
7.1 | December 1, 2019 | [SCLO](https://www.softwarecollections.org/en/scls/rhscl/rh-php71/) | [RedHat](https://developers.redhat.com/products/softwarecollections/overview/)
7.2 | November 30, 2020 | [SCLO](https://www.softwarecollections.org/en/scls/rhscl/rh-php72/) | [RedHat](https://developers.redhat.com/products/softwarecollections/overview/)

### End-of-Life (EOL) ###

Catapult tracks vendor announced EOL dates for website software and a red EOL date will be displayed during `vagrant status` if one of your website's software is EOL. Currently Catapult has no plan to block Catapult supported software that is past its EOL date - it is up to you to move to the next major supported version.

## Competition ##

The free market and competition is great - it pushes the envelope of innovation. Here, we compare similar platforms to shed light on where we are and we're headed. Catapult's approach is holistic, meaning, there are no optional features - the platform includes everything in its default state and its default state is the only state of the platform. Some platforms offer and support optional third-party features that need configured - these are excluded.

Platform Feature | Catapult | Pantheon | Acquia
-----------------|----------|----------|--------
Source                                        | Open                                  | Closed                        | Closed
Subscription Feature Set                      | Bundled                               | Separated                     | Separated
Traditional Tooling (VMs & Shell)             | :white_check_mark:                    | :x:                           | :x:
Multi-Platform (Linux & Windows)              | :white_check_mark:                    | :x:                           | :x:
Supported PHP Software                        | 20+                                   | 2                             | 1
Supported .NET Software                       | TBA                                   | :x:                           | :x:
Minimum Bundled<br>Monthly Cost               | $45                                   | $400                          | $134
Websites per instance                         | Unlimited                             | 1                             | 1
Managed Workflow                              | Git Flow (branch-based environments)  | :x:                           | :x:
Managed Software Workflow Model               | Upstream or Downstream                | :x:                           | :x:
Agile Methodology Focus                       | Scrum                                 | :x:                           | :x:
Managed Continuous Integration                | :white_check_mark:                    | :x:                           | :x:
Environments                                  | LocalDev, Test, QC, Production        | Multidev, Dev, Test, Live     | Dev Desktop, Dev, Stage, Prod
Exacting Configuration                        | :white_check_mark:                    | :x:<sup>[2](#references)</sup>| :x:<sup>[3](#references)</sup>
Approach                                      | Virtual Machine                       | Container                     | Virtual Machine
Data Center                                   | DigitalOcean and AWS                  | Rackspace                     | AWS
Scaling                                       | Vertical                              | Horizontal                    | Vertical
Scaling Management                            | Manual                                | Automatic                     | Manual
Development Environment                       | Unlimited Local                       | 5 Cloud                       | Unlimited Local
Development Environment Approach              | Exact                                 | Exact                         | Similar
Dashboard - Control                           | CLI                                   | CLI & Web                     | CLI & Web
Dashboard - Monitor                           | Web                                   | Web                           | Web
Managed Public Git Website Repository Support | GitHub & Bitbucket                    | :x:                           | :x:
Managed DNS                                   | CloudFlare                            | :x:                           | :x:
Managed Free HTTPS Certificates               | CloudFlare/Let's Encrypt              | :x:                           | :x:
Managed Server Monitoring                     | New Relic                             | :x:                           | Proprietary
Managed Application Error Logs                | New Relic                             | Proprietary                   | Proprietary
Managed Application Performance Monitoring    | New Relic                             | :x:                           | :x:
Managed Browser Performance Monitoring        | New Relic                             | :x:                           | :x:
Managed Synthetic Monitoring                  | New Relic                             | :x:                           | :x:

See an error or have a suggestion? Email competition@devopsgroup.io - we appreciate all feedback.



## Table of Contents ##

- [Catapult](#catapult)
    - [Platform Overview](#platform-overview)
    - [Security Disclosure](#security-disclosure)
    - [Supported Website Software](#supported-website-software)
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
    - [Software Workflow](#software-workflow)
        - [Downstream](#downstream)
        - [Upstream](#upstream)
    - [Catapult Configuration](#catapult-configuration)
        - [Company](#company)
        - [Environments](#environments)
        - [Websites](#websites)
    - [Website Development](#website-development)
        - [Website Repositories](#website-repositories)
        - [Software Fresh Installs](#software-fresh-installs)
        - [Software Auto Updates](#software-auto-updates)
        - [HTTPS and Certificates](#https-and-certificates)
        - [Forcing www](#forcing-www)
        - [Debug Output](#debug-output)
        - [Cache Busting](#cache-busting)
        - [Progressive Web App](#progressive-web-app)
        - [Email](#email)
        - [Upload Limits](#upload-limits)
        - [Database Migrations](#database-migrations)
        - [Refreshing Databases](#refreshing-databases)
        - [Connecting to Databases](#connecting-to-databases)
        - [Production Hotfixes](#production-hotfixes)
    - [Automated Deployment Cycle](#automated-deployment-cycle)
    - [Maintenance Cycle](#maintenance-cycle)
        - [Daily](#daily)
        - [Weekly](#weekly)
    - [Disaster Recovery](#disaster-recovery)
        - [Server Rebuilding](#server-rebuilding) 
        - [Website Rollbacks](#website-rollbacks)
- [Security](#security)
    - [Preventive Controls](#preventive-controls)
    - [Detective Controls](#detective-controls)
    - [Corrective Controls](#corrective-controls)
    - [Data Protection](#data-protection)
        - [United States](#united-states)
        - [Europe](#europe)
- [Compliance](#compliance)
    - [Cloud Compliance](#cloud-compliance)
    - [Self Compliance](#self-compliance)
- [Performance](#performance)
    - [Bandwidth Optimizations](#bandwidth-optimizations)
    - [Caching Optimizations](#caching-optimizations)
    - [Geographic Optimizations](#geographic-optimizations)
    - [Recommended Optimizations](#recommended-optimizations)
- [Performance Testing](#performance-testing)
    - [Website Concurrency Maximum](#website-concurrency-maximum)
    - [Interpreting Apache AB Results](#interpreting-apache-ab-results)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
    - [Releases](#releases)
- [Community](#community)



# Setup Catapult #

Catapult requires a [Developer Setup](#developer-setup), [Instance Setup](#instance-setup), and [Services Setup](#services-setup) as described in the following sections.

**Please Note:**
* You must run most commands from an elevated shell. For macOS and Linux, type `sudo su` in a terminal window, or for Windows, right-clicking on Command Prompt from the Start Menu and selecting "Run as Administrator".
* It is advised to turn off any antivirus software that you may have installed during setup and usage of Catapult - tasks such as forwarding ports and writing hosts files may be blocked.
* Virtualizaion must be enabled in the BIOS of the developer's workstation - follow [this how-to](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Virtualization/sect-Virtualization-Troubleshooting-Enabling_Intel_VT_and_AMD_V_virtualization_hardware_extensions_in_BIOS.html) to get started.
* Using a VPN client during usage of LocalDev may result in lost communication between your workstation and the guests, requiring a `vagrant reload` to regain SSH and/or WinRM communication.

## Developer Setup ##

Catapult is controlled via Vagrant and the command line of a developer's workstation - below is a list of required software that will need to be installed.

* macOS workstations: Compatible and supported
* Linux workstations: Compatible and supported
* Windows workstations: Limited testing and support

1. **Vagrant**
    * **Using macOS?**
        1. Ensure Xcode Command Line Tools are installed by running `xcode-select --install` from Terminal
        2. Download and install the latest version of Vagrant v2.x from https://releases.hashicorp.com/vagrant/
    * **Using Windows?**
        1. Download and install the latest version of Vagrant v2.x from https://releases.hashicorp.com/vagrant/
    * **Using Linux (Debian, Ubuntu)?**
        1. Download the latest version of Vagrant v2.x respective to your architecture from https://releases.hashicorp.com/vagrant/ by running e.g. `wget https://releases.hashicorp.com/vagrant/2.2.2/vagrant_2.2.2_x86_64.deb`
        2. Install Vagrant using dpkg e.g. `sudo dpkg --install vagrant_2.2.2_x86_64.deb`
        3. Install Network File System (NFS) `sudo apt-get install nfs-kernel-server`
    * **Using Linux (Fedora, Red Hat, Suse)?**
        1. Download the latest version of Vagrant v2.x respective to your architecture from https://releases.hashicorp.com/vagrant/ by running e.g. `wget https://releases.hashicorp.com/vagrant/2.2.2/vagrant_2.2.2_x86_64.rpm`
        2. Install Vagrant using yum e.g. `sudo yum install vagrant_2.2.2_x86_64.rpm`
2. **Vagrant Plugins**
    1. Open your command line and install the following Vagrant plugins:
        1. `vagrant plugin install vagrant-aws`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-aws.svg)](https://rubygems.org/gems/vagrant-aws)
        2. `vagrant plugin install vagrant-digitalocean`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-digitalocean.svg)](https://rubygems.org/gems/vagrant-digitalocean) We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-digitalocean)
        3. `vagrant plugin install vagrant-hostmanager`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-hostmanager.svg)](https://rubygems.org/gems/vagrant-hostmanager) We maintain this project! [GitHub](https://github.com/smdahlen/vagrant-hostmanager)
        4. `vagrant plugin install vagrant-vbguest`
            * [![Gem](https://img.shields.io/gem/dt/vagrant-vbguest.svg)](https://rubygems.org/gems/vagrant-vbguest)
3. **VirtualBox**
    * **Using macOS?**
        1. Download and install the latest version of VirtualBox v5.2 from https://www.virtualbox.org/wiki/Downloads
    * **Using Windows?**
        1. Download and install the latest version of VirtualBox v5.2 from https://www.virtualbox.org/wiki/Downloads
    * **Using Linux (Debian, Ubuntu)?**
        1. Download and install the latest version of VirtualBox v5.2 using Advanced Packaging Tool (APT) `sudo apt-get install virtualbox`
    * **Using Linux (Fedora, Red Hat, Suse)?**
        1. Download and install the latest version of VirtualBox v5.2 using Yellowdog Updater, Modifed (yum) `sudo yum install virtualbox`
4. **GPG2**
    * **Using macOS?**
        1. Download and install GPG Suite from https://gpgtools.org
    * **Using Windows?**
        1. Download and install Gpg4win from http://gpg4win.org/download.html
    * **Using Linux?**
        1. GPG is included in the base distribution in most cases.
        1. If being prompted by the Passphrase GUI Agent, comment out 'use-agent' in `~/.gnupg/gpg.conf`
5. **Git**
    * **Using macOS?**
        1. Git commandline is included in the base distribution in most cases.
        1. For a streamlined Git GUI, download and install SourceTree from https://www.sourcetreeapp.com/
    * **Using Windows?**
        1. Download and install SourceTree from https://www.sourcetreeapp.com/
    * **Using Linux?**
        1. Git commandline is included in the base distribution in most cases.
        1. For a streamlined Git GUI, download and install SmartGit from http://www.syntevo.com/smartgit/
6. **Terminal**
    * **Using macOS?**
        1. The terminal in the base distrubitions are 100% compatible.
    * **Using Windows?**
        1. Download and install Cygwin from https://cygwin.com/install.html
            * Make sure to install the openssh package
        1. Run all Vagrant commands from within the Cygwin terminal.
            * Make sure to open Cygwin terminal as Administrator by right-clicking and selecting "Open as Administrator"
    * **Using Linux?**
        1. The terminal in the base distrubitions are 100% compatible.


Having your team use the same tools is beneficial to streamlining your workflow - below is a list of recommended software tools.

1. **Sublime Text 3**
    1. Please download and install from http://www.sublimetext.com/3


## Instance Setup ##

Catapult is quick to setup. You have the option of using GitHub (public) or Bitbucket (private) to store your Catapult instance. Your Catapult secrets are encrypted and safe, but please use your best judgment when choosing a destination for your Catapult instance.

1. **Fork Catapult**
    * **GitHub (public)**
        1. Fork https://github.com/devopsgroup-io/catapult and clone via SourceTree or the git utility of your choice.
    * **BitBucket (private)**
        1. From BitBucket, create a new repository and import https://github.com/devopsgroup-io/catapult. Then clone via SourceTree or the git utility of your choice.
2. **SSH Key Pair**
    1. Create a *passwordless* SSH key pair - this will drive authentication for Catapult.
        1. For instructions please see https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/
        2. Place the newly created *passwordless* SSH key pair `id_rsa` and `id_rsa.pub` in the `~/secrets/` folder.
3. **GPG Key**
    1. Generate a GPG key - this will drive encryption for Catapult.
        1. NEVER SHARE THE KEY WITH ANYONE OTHER THAN YOUR TEAM.
        3. Spaces are not permitted and must be at least 20 characters.
        4. To create a strong key, please visit https://xkpasswd.net/
        5. Place your newly generated GPG key at `~/secrets/configuration-user.yml["settings"]["gpg_key"]`
        6. It is recommended to print a QR code of the key to distribute to your team, please visit http://educastellano.github.io/qr-code/demo/
        7. Remember! Security is 99% process and 1% technology.
4. **GPG Edit Mode**
    1. **GPG Edit Mode** is set at `~/secrets/configuration-user.yml["settings"]["gpg_edit"]` (`false` by default) and is used to encrypt your Catapult configuration secrets using your **GPG Key**:
        1. `~/secrets/id_rsa` as `~/secrets/id_rsa.gpg`
        2. `~/secrets/id_rsa.pub` as `~/secrets/id_rsa.pub.gpg`
        3. `~/secrets/configuration.yml` as `~/secrets/configuration.yml.gpg`
    1. **GPG Edit Mode** requires that you are on your Catapult fork's `develop` branch.
    3. Running any Vagrant command (e.g. `vagrant status`) will encrypt your configuration, of which, will allow you to commit and push safely to your public Catapult fork.



## Services Setup ##

Catapult is designed with a distributed services model, below are the required third-party services and their sign-up and configuration steps.

Service | Product | Use Case | Monthly Cost
--------|---------|----------|-------------
&dagger;Cloud Hosting: Red Hat (PHP) | DigitalOcean Droplets | Web and Database Servers (6) | \*$30+
&dagger;Cloud Hosting: Windows (.NET) | Amazon Web Services (AWS) EC2 | Web and Database Servers (6) | \*$80+
Source Code Repositories | Atlassian Bitbucket | Private Repositories | Free
Source Code Repositories | GitHub | Public Repositories | Free
Continuous Integration | Atlassian Bamboo Server | Build Server | $15
DNS | CloudFlare | Cloud DNS | Free
Monitoring | New Relic Application Performance Monitoring (APM), Browser, Server, and \**Synthetics | Performance and Infrastructure Monitoring | Free
**Total** | | | &dagger;$45+

&dagger; Only one platform (Red Hat or Windows) is required to have a full-featured infrastructure. Generally speaking, the industry standard Red Hat platform will be used.

\* Depending on load, resources may need to be increased, starting at an additional [$5 per month per server](https://www.digitalocean.com/pricing/).

\** New Relic customers receive a trial "pro" period ranging from 14-days to 30-days, however, there is [no free tier beyond the trial](#partnerships)

### 1. **Cloud Hosting:**
1. **DigitalOcean** sign-up and configuration
    1. Create an account at http://digitalocean.com
       * [Free Stuff] Get a $10 credit and give us $25 once you spend $25 https://www.digitalocean.com/?refcode=6127912f3462
    2. Go to your DigitalOcean Applications & API Dashboard https://cloud.digitalocean.com/settings/api
        1. Create a Personal Access Token named "Vagrant" and place the token value at `~/secrets/configuration.yml["company"]["digitalocean_personal_access_token"]`
    3. Go to your DigitalOcean Security Dashboard https://cloud.digitalocean.com/settings/security
        1. Add a new SSH Key named "Vagrant" with your newly created `id_rsa.pub` from `~/secrets/id_rsa.pub` key 
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
        1. Select "N. Virginia" from the top navigation
        2. Click Import Key Pair
        3. Add your newly created `id_rsa.pub` from `~/secrets/id_rsa.pub` key
        4. Set the Key pair name to "Catapult"
    7. Go to your AWS EC2 Security Groups Dashboard https://console.aws.amazon.com/ec2/home#SecurityGroups
        1. Select the "default" Group Name
        2. Select the Inbound tab and click Edit
        3. Change Source to "Anywhere"
        4. Click Save

### 2. **Repositories:**
Bitbucket provides free private repositories and GitHub provides free public repositories, you will need to sign up for both. If you already have Bitbucket and GitHub accounts you may use them, however, it's best to setup a [machine user](https://developer.github.com/guides/managing-deploy-keys/#machine-users) if you're using Catapult with your team.

1. **Bitbucket** sign-up and configuration
    1. Create an account at https://bitbucket.org
        1. Place the username (not the email address) that you used to sign up for Bitbucket at `~/secrets/configuration.yml["company"]["bitbucket_username"]`
        2. Place the password of the account for Bitbucket at `~/secrets/configuration.yml["company"]["bitbucket_password"]`
    2. Add your newly created `id_rsa.pub` from `~/secrets/id_rsa.pub` key in https://bitbucket.org/account/user/`your-user-here`/ssh-keys/ named "Catapult"
2. **GitHub** sign-up and configuration
    1. Create an account at https://github.com
        1. Place the username (not the email address) that you used to sign up for GitHub at `~/secrets/configuration.yml["company"]["github_username"]`
        2. Place the password of the account for GitHub at `~/secrets/configuration.yml["company"]["github_password"]`
    2. Add your newly created `id_rsa.pub` from `~/secrets/id_rsa.pub` key in https://github.com/settings/ssh named "Catapult"

### 3. **Automated Deployments:**

**Bamboo Server set-up**

1. Sign up for an Atlassian account at https://my.atlassian.com/
2. Purchase the $10 Bamboo Server license from https://www.atlassian.com/purchase/product/bamboo 
3. It's now time to bring up your build server, please run `vagrant up ~/secrets/configuration.yml["company"]["name"]-build`
    * The initial `up` will take some time for, please be patient
4. Login to DigitalOcean to obtain the IP address of the virtual machine to access via URL
    * Place your Bamboo base URL at `~/secrets/configuration.yml["company"]["bamboo_base_url"]`, the format should be http://[digitalocean-ip-here]/
5. Once your Bamboo Server instance is accessible via URL, you will be prompted with a license prompt, enter your license.
6. You will next be prompted to enter the following information:
    * Username (required) - root
    * Password (required) - specify a complex password
    * Confirm password (required)
    * Full name (required) - use `~/secrets/configuration.yml["company"]["name"]`
    * Email - use `~/secrets/configuration.yml["company"]["email"]`

**Bamboo Configuration**

To avoid having to manually configure the Bamboo project, plans, stages, jobs, and tasks configuration, you may optionally install and purchase the "Bob Swift Atlassian Add-ons - Bamboo CLI Connector" Bamboo add-on. Otherwise, the manual setup configuration steps are outlined below:

1. Place your Bamboo username at `~/secrets/configuration.yml["company"]["bamboo_username"]`
    * Normally root for Bamboo Server
2. Place your Bamboo password at `~/secrets/configuration.yml["company"]["bamboo_password"]`
3. Disable anonymous user access by clicking the gear at the top right and going to Overview
    1. Next, under Security, go to Global permissions and remove Access from Anonymous Users
4. Click Create > Create a new plan from the top navigation:
    1. **Create Catapult Project and create BUILD Plan**
        * *Project and build plan name*
            1. Project > New Project
            2. Project name: Catapult
            3. Project key: CAT
            4. Plan name: BUILD
            5. Plan key: BUILD
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    2. **Create Catapult Project and create TEST Plan**
        * *Project and build plan name*
            1. Project > New Project
            2. Project name: Catapult
            3. Project key: CAT
            4. Plan name: TEST
            5. Plan key: TEST
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    3. **Create QC Plan**
        * *Project and build plan name*
            1. Project: Catapult
            4. Plan name: QC
            5. Plan key: QC
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    4. **Create PROD Plan**
        * *Project and build plan name*
            1. Project: Catapult
            4. Plan name: PROD
            5. Plan key: PROD
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    5. **Create WINTEST Plan**
        * *Project and build plan name*
            1. Project: Catapult
            4. Plan name: WINTEST
            5. Plan key: WINTEST
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    6. **Create WINQC Plan**
        * *Project and build plan name*
            1. Project: Catapult
            4. Plan name: WINQC
            5. Plan key: WINQC
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None
    7. **Create WINPROD Plan**
        * *Project and build plan name*
            1. Project: Catapult
            4. Plan name: WINPROD
            5. Plan key: WINPROD
            6. Plan description:
        * *Link repository to new build plan*
            1. Repository host: Other > None

### 4. **DNS:**
1. **CloudFlare** sign-up and configuration
    1. Create a CloudFlare account at https://www.cloudflare.com
    2. Sign in to your new CloudFlare account
    3. Visit your My Account section at https://www.cloudflare.com/a/account/my-account and scroll down to your Global API Key and place the token value at `~/secrets/configuration.yml["company"]["cloudflare_api_key"]`
    4. Place the email address of the email address that you used to sign up for CloudFlare at `~/secrets/configuration.yml["company"]["cloudflare_email"]`

### 5. **Monitoring:**
1. **New Relic** sign-up and configuration
    1. Create a New Relic account at http://newrelic.com/
        * [Free Stuff] Sign-up up for New Relic and get a Data Nerd shirt! http://newrelic.com/lp/datanerd
        * [Free Stuff] Refer Catapult and get a New Relic hoodie! http://newrelic.com/referral
    2. Sign in to your New Relic account
    3. Go to your Account Settings > Integrations > API keys.
    4. Generate and place your REST API key at `~/secrets/configuration.yml["company"]["newrelic_api_key"]`
    5. Generate and place your Admin API key at `~/secrets/configuration.yml["company"]["newrelic_admin_api_key"]`
    6. Go to your Account Settings > Account > Summary.
    7. Place your License key at `~/secrets/configuration.yml["company"]["newrelic_license_key"]`

### 6. **Email:**
1. **SendGrid** sign-up and configuration
    1. Create a SendGrid account at https://sendgrid.com/
        1. Place the username that you used to sign up for SendGrid at `~/secrets/configuration.yml["company"]["sendgrid_username"]`
        2. Place the password of the account for SendGrid at `~/secrets/configuration.yml["company"]["sendgrid_password"]`
    2. Sign in to your SendGrid account
    3. Go to Settings > API Keys.
    4. Generate an API key named "Catapult" and place at `~/secrets/configuration.yml["company"]["sendgrid_api_key"]`

### 7. **Verify Configuration:**
1. To verify all of the configuration that you just set, open your command line and change directory into your fork of Catapult, then run `vagrant status`. Catapult will confirm connection to all of the Services and inform you of any problems.



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

Once the Web and Database Servers are up and running, it's then time to configure your Bamboo Catapult project's TEST, QC, and PROD plans. To avoid having to manually configure the Bamboo project, plans, stages, jobs, and tasks configuration, you may optionally install and purchase the "Bob Swift Atlassian Add-ons - Bamboo CLI Connector" Bamboo add-on. Otherwise, the manual setup configuration steps are outlined below:

1. Sign in to your new custom Bamboo instance `~/secrets/configuration.yml["company"]["bamboo_base_url"]`
2. Click Build > All build plans from the header:
3. From the Build Dashboard and under the Catapult project:
    * **Configure Catapult Project BUILD Plan**
        1. Click the edit icon for the BUILD plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            6. Script body: `bash /catapult/provisioners/redhat/provision.sh "build" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "bamboo"`
            7. Click Save
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
    * **Configure Catapult Project WINTEST Plan**
        1. Click the edit icon for the WINTEST plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["test"]["servers"]["windows"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["test"]["servers"]["windows"]["admin_password"]" "test" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "iis"`
            5. Click Save
        5. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["test"]["servers"]["windows_mssql"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["test"]["servers"]["windows_mssql"]["admin_password"]" "test" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mssql"`
            5. Click Save
    * **Configure Catapult Project WINQC Plan**
        1. Click the edit icon for the WINQC plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["qc"]["servers"]["windows"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["qc"]["servers"]["windows"]["admin_password"]" "qc" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "iis"`
            5. Click Save
        5. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["qc"]["servers"]["windows_mssql"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["qc"]["servers"]["windows_mssql"]["admin_password"]" "qc" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mssql"`
            5. Click Save
    * **Configure Catapult Project WINPROD Plan**
        1. Click the edit icon for the WINPROD plan
        2. From the Stages tab, select Default Job
        3. Remove all tasks that may have been added by default during initial setup
        4. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["production"]["servers"]["windows"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["production"]["servers"]["windows"]["admin_password"]" "production" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "iis"`
            5. Click Save
        5. Click Add task
            1. Search for Script Task and select it
            2. Interpreter: `shell`
            3. Script Location: `Inline`
            4. Script body: `python /catapult/provisioners/windows/provision.py "~/secrets/configuration.yml["environments"]["production"]["servers"]["windows_mssql"]["ip"]" "Administrator" "~/secrets/configuration.yml["environments"]["production"]["servers"]["windows_mssql"]["admin_password"]" "production" "https://github.com/[your-name-here]/catapult" "~/secrets/configuration-user.yml["settings"]["gpg_key"]" "mssql"`
            5. Click Save



# Release Management #

Catapult follows Gitflow for its **infrastructure configuration** *and* **website development** model - each environment is branch-based and changesets are introduced into each environment by pull requests from one branch to the next.

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_release_management.png" alt="Catapult Release Management">
<sup>[1](#references)</sup>

|            | LocalDev | Test | QC | Production
|------------|----------|------|----|-----------
**Running Branch**                                       | *develop*                                                   | *develop*                                                                                                      | *release*                                                      | *master*
**Automated Deployments**                                | No, manually via `vagrant provision`                        | Yes, triggered by new commits to **develop**                                                                   | Yes, nightly or manually via Bamboo                            | Yes, nightly or manually via Bamboo
**Testing Activities**                                   | Component Test                                              | Integration Test, System Test                                                                                  | Acceptance Test, Release Test                                  | Operational Qualification
**Scrum Activity**                                       | Sprint Start: Development of User Stories                   | Daily Scrum                                                                                                    | Sprint Review                                                  | Sprint End: Accepted Product Release
**Scrum Roles**                                          | Development Team                                            | Scrum Master, Development Team, Product Owner (optional)                                                       | Scrum Master, Development Team, Product Owner                  | Product Owner

## Software Workflow ##

Catapult enforces a unique solution to Release Management of a website, Software Workflow. Software Workflow offers two modes, downstream or upstream, creating a "golden environment".

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_software_workflow.png" alt="Catapult Software Workflow">

### Downstream ###

|            | LocalDev | Test | QC | Production
|------------|----------|------|----|-----------
**Downstream Software Workflow - Database**              | Restore from **develop** `~/_sql` folder of website repo    | Restore from **develop** `~/_sql` folder of website repo                                                       | Restore from **release** `~/_sql` folder of website repo       | Auto-commit one backup per day (up to 500MB or 1) to **master** `~/_sql` folder of website repo
**Downstream Software Workflow - Untracked File Stores** | rsync file stores from **Production**                       | rsync file stores from **Production**                                                                          | rsync file stores from **Production**                          | 
**Downstream Software Workflow - Tracked File Stores**   | Pull file stores from **develop**                           | Pull file stores from **develop**                                                                              | Pull file stores from **release**                              | Auto-commit file stores (up to 750MB each) to **master** of website repo

**Note:** Catapult will automatically pull the **master** branch into the **develop** branch of a website's repository when in the **Downstream Software Workflow** direction.

### Upstream ###

|            | LocalDev | Test | QC | Production
|------------|----------|------|----|-----------
**Upstream Software Workflow - Database**                | Restore from **develop** `~/_sql` folder of website repo    | Auto-commit one backup per day (up to 500MB or 1) to **develop** `~/_sql` folder of website repo | Restore from **release** `~/_sql` folder of website repo       | Restore from **master** `~/_sql` folder of website repo
**Upstream Software Workflow - Untracked File Stores**   | rsync file stores from **Test**                             |                                                                                                  | rsync file stores from **Test**                                | rsync file stores from **Test**
**Upstream Software Workflow - Tracked File Stores**     | Pull file stores from **develop**                           | Auto-commit file stores (up to 750MB each) to **develop** of website repo                        | Pull file stores from **release**                              | Pull file stores from **master**

## Catapult Configuration ##

All Catapult configuration is stored in `~/secrets/configuration.yml` and encrypted as `~/secrets/configuration.yml.gpg`. There are three main sections - [Company](#company), [Environments](#environments), and [Websites](#websites).

### Company ###

The exclusive Company entry contains top-level company information and service credentials, configured during [Setup Catapult](#setup-catapult).

* `name:`
    * required: yes
        * Your company's name or your name
* `email:`
    * required: yes
        * The primary contact email
* `timezone_redhat:`
    * required: yes
        * Your company's timezone in tz database format
        * See [this list](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Virtualization/3.1/html/Developer_Guide/appe-REST_API_Guide-Timezones.html) for a list of valid tz database format timezones
* `timezone_windows:`
    * required: yes
        * Your company's timezone in Windows Standard Format
        * See [this list](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Virtualization/3.1/html/Developer_Guide/appe-REST_API_Guide-Timezones.html) for a list of valid Windows Standard Format timezones

The remaining keys include credentials to services, ideally rotated on a bi-annual basis. When rotated, all Bamboo builds need to be disabled and then the configuration changes merged into all branches of your Catapult's fork (`develop` > `release` > `master`), then builds enabled.

* `digitalocean_personal_access_token`
* `bitbucket_username`
* `bitbucket_password`
* `github_username`
* `github_password`
* `bamboo_base_url`
* `bamboo_username`
* `aws_access_key`
* `aws_secret_key`
* `bamboo_password`
* `cloudflare_api_key`
* `cloudflare_email`
* `newrelic_admin_api_key`
* `newrelic_api_key`
* `newrelic_license_key`


### Environments ###

The setup- and maintenance-free Environments entries contain environment configurations such as IP addresses and system credentials - all of which are automatically set during [Setup Catapult](#setup-catapult) and [Setup Environments](#setup-environments).

### Websites ###

Adding websites to Catapult is driven by simple configuration. After establishing a repository at GitHub or Bitbucket, simply add entries to `~/secrets/configuration.yml`. The entries must be ordered alphabetically by domain name and all entries exist under the single `websites:` key as reflected in this example:
```
websites:
  apache:
  - domain: devopsgroup.io
    repo: git@github.com:devopsgroup-io/devopsgroup-io.git
  - domain: example.com
    repo: git@github.com:example-company/example.com.git
```

The following options are available:

* `domain:`
    * required: yes
    * example: `domain: example.com`
    * example: `domain: subdomain.example.com`
        * this root domain entry is the Production canonical domain name without `www.`
            * a `www.` subdomain is created for you
            * the key for all management orchestration of this website
        * one subdomain level is supported for this root domain entry (`subdomain.example.com`)
        * manages DNS of LocalDev (via hosts file) and Test, QC, Production (via CloudFlare)
            * `dev.example.com`, `test.example.com`, `qc.example.com`, `example.com`
            * `www.dev.example.com`, `www.test.example.com`, `www.qc.example.com`, `www.example.com`
* `domain_tld_override:`
    * required: no
    * example: `domain_tld_override: mycompany.com`
        * a domain name under your [name server authority](https://en.wikipedia.org/wiki/Domain_Name_System#Authoritative_name_server) to append to the top-level-domain (e.g. `.com`)
            * useful when you cannot or do not wish to host the Test/QC website at the `domain`
        * appends the `domain_tld_override` for Environments
            * `dev.example.com.mycompany.com`, `test.example.com.mycompany.com`, `qc.example.com.mycompany.com`, `example.com.mycompany.com`
            * `www.dev.example.com.mycompany.com`, `www.test.example.com.mycompany.com`, `www.qc.example.com.mycompany.com`, `www.example.com.mycompany.com`
        * PLEASE NOTE: When removing this option from a website with `software:`, you need to manually replace URLs in the database respective to the `software_workflow:` option.
            * ie `vagrant ssh mycompany.com-test-redhat-mysql`
            * `wp-cli --allow-root --path="/var/www/repositories/apache/example.com/(webroot if applicable)" search-replace ":\/\/(www\.)?(dev\.|test\.)?(example\.com\.mycompany\.com)" "://example.com" --regex`
* `force_auth:`
    * required: no
    * example: `force_auth: letmein`
        * forces [HTTP basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) in LocalDev, Test, QC, and Production (see `force_auth_exclude`)
        * `letmein` is both the username and password
* `force_auth_exclude:`
    * required: no
    * dependency: `force_auth:`
    * example: `force_auth_exclude: ["production"]`
        * array of select environments `["dev","test","qc","production"]` to exclude from the `force_auth` option
* `force_https:`
    * required: no
    * option: `force_https: true`
        * rewrites all http traffic to https
        * all `dev.` domains in LocalDev will have an unsigned certificate warning
        * free certificates are created and managed for you compliments of CloudFlare (single-subdomain) and Let's Encrypt (multi-subdomain)
* `force_ip:`
    * required: no
    * example: `force_ip: ["208.80.154.224"]`
        * an array of valid IPv4 or IPv6 addresses that denies all traffic except for traffic coming from the defined addresses
        * option applies to LocalDev, Test, QC, and Production unless `force_ip_exclude` is defined
        * can be used as an alternative to `force_auth` for when HTTP basic authentication cannot be used. e.g. [Drupal 8 Basic Auth Module](https://www.drupal.org/project/drupal/issues/2842858)
        * can be used in addition to `force_auth` for added security
* `force_ip_exclude:`
    * required: no
    * dependency: `force_ip:`
    * example: `force_ip_exclude: ["production"]`
        * array of select environments `["dev","test","qc","production"]` to exclude from the `force_ip` option
* `repo:`
    * required: yes
    * example: `repo: git@github.com:devopsgroup-io/devopsgroup-io.git`
        * the existing source code repository of your website (repo automatically created if none exists)
        * GitHub and Bitbucket over SSH are supported, HTTPS is not supported
* `software:`
    * required: no
    * description: manages many aspects of software respective to each environment for websites with supported software types
        * maintains software database config file
        * manages tracked and untracked software file stores intelligently via git and rsync
        * manages permissions of software file store containers
        * manages software operations such as cron, garbage collection, and caches
        * manages software database migrations
        * manages software database backups and restores intelligently via git
        * manages software url references in database
        * manages software admininistrator account integrity
    * option: `software: codeigniter2`
    * option: `software: codeigniter3`
    * option: `software: concrete58`
    * option: `software: drupal6`
    * option: `software: drupal7`
    * option: `software: drupal8`
    * option: `software: elgg1`
    * option: `software: expressionengine3`
    * option: `software: joomla3`
    * option: `software: laravel5`
    * option: `software: mediawiki1`
    * option: `software: moodle3`
    * option: `software: silverstripe3`
    * option: `software: suitecrm7`
    * option: `software: wordpress4`
    * option: `software: wordpress5`
    * option: `software: xenforo1`
    * option: `software: xenforo2`
    * option: `software: zendframework2`
* `software_auto_update:`
    * required: no
    * dependency: `software:`
    * option: `software_auto_update: true`
        * manages software core and pluggable component (plugins, modules, etc) updates to the latest compatible versions using the software's CLI tool or similiar method
        * updates only occur in the `software_workflow` environment
        * not all `software` is supported, see [Software Auto Updates](#software-auto-updates)
* `software_dbprefix:`
    * required: no
    * dependency: `software:`
    * example: `software_dbprefix: wp_`
        * the value that prefixes table names within the database
            * PLEASE NOTE: table prefixes included in software distributions, such as WordPress' `wp_`, must be specified if desired
* `software_dbtable_retain:`
    * required: no
    * dependency: `software:`
    * dependency: `software_workflow: upstream`
    * example: `software_dbtable_retain: ["comments","commentmeta"]`
        * array of tables, excluding the `software_dbprefix:`, to retain from the Production environment when `software_workflow:` is set to `upstream`
        * this will backup and commit a `YYYYMMDD_software_dbtable_retain.sql` file to `~/_sql`
        * this is useful in a content regulated situation when moving a database upstream is necessary, however, needing to retain a table that includes, for example, a table of contact form submissions
* `software_workflow:`
    * required: yes
    * dependency: `software:`
    * option: `software_workflow: downstream`
        * this option is useful for maintaining a website
        * specifies the Production environment and the `master` branch as the source and automated save point for software files and database
        * the `master` branch is automatically merged into the `develop` branch for convenience
    * option: `software_workflow: upstream`
        * this option is useful for launching a new website or maintaining a regulated website
        * specifies the Test environment and the `develop` branch as the source and automated save point for software files and database
        * REMINDER: websites with this option will have its Production instance overwritten with software files and datbase from the `master` branch - see [Release Management](#release-management)
* `webroot:`
    * required: no
    * example: `webroot: www/`
        * if the webroot differs from the repo root, specify it here
        * must include the trailing slash



## Website Development ##

Website development is done on the developer's workstation using the LocalDev environment for local and realtime software development in an environment that is exactly matchinng to upstream environments.

### Website Repositories ###

Once websites are added to your configuration and you have performed a provision of your LocalDev environment, repositories for websites are cloned into your Catapult instance at `~/repositories` and into the respective `apache` or `iis` folder, listed by domain name. Website repository folders are linked between the developer's workstation (host) and the LocalDev environment (guest) for realtime development.

### Software Fresh Installs ###

Catapult enforces software configuration best practice for software fresh installs. A typical software fresh install workflow would be to fork the software project on GitHub and add then add a new website entry to your `~/configuration.yml` file. Given the broad spectrum of software requirements there are minor configuration caveats worth noting:

Software | Install Approach | Install Notes
---------|------------------|--------------
`codeigniter2`      |          | Follow the [Installation Instructions](https://www.codeigniter.com/userguide2/installation/index.html).
`codeigniter3`      |          | Follow the [Installation Instructions](https://www.codeigniter.com/userguide3/installation/index.html).
`concrete58`        | Download | Download [concrete5](https://www.concrete5.org/download).
`drupal6`           | Drush    | `drush pm-download drupal-6`
`drupal7`           | Drush    | `drush pm-download drupal-7`
`drupal8`           | Drush    | `drush pm-download drupal-8`
`elgg1`             | Fork     | Follow the installation [Overview](http://learn.elgg.org/en/2.0/intro/install.html). Catapult requires the `dataroot` directory to be within the webroot, it's pertinant to create a `.gitignore` to ignore and `.htaccess` to deny access to this directory.
`elgg2`             | Fork     | Follow the installation [Overview](http://learn.elgg.org/en/2.0/intro/install.html). Catapult requires the `dataroot` directory to be within the webroot, it's pertinant to create a `.gitignore` to ignore and `.htaccess` to deny access to this directory.
`expressionengine3` | Download |
`joomla3`           | Fork     |
`laravel5`          | Composer | Follow the [Composer Create-Project](https://laravel.com/docs/5.0/installation) documentation.
`mediawiki1`        | Fork     |
`moodle3`           | Fork     | Catapult requires the `moodledata` directory to be within the webroot, it's pertinant to create a `.gitignore` to ignore and `.htaccess` to deny access to this directory.
`silverstripe3`     | Composer | Follow the [Installing and Upgrading with Composer](https://docs.silverstripe.org/en/3.4/getting_started/composer/). During a fresh install, the database config file `mysite/_config.php` will need to be given 0777 permissions.
`suitecrm7`         | Fork     |
`wordpress4`        | Fork     |
`wordpress5`        | Fork     |
`xenforo1`          | Download |
`xenforo2`          | Download |
`zendframework2`    | Fork     | Your best bet is to start from the [zendframework/ZendSkeletonApplication](https://github.com/zendframework/ZendSkeletonApplication) GitHub project. Catapult assumes Zend Framwork is at the root of your repo and writes a database config file at `config/autoload/global.php`, you will also need to set `webroot: public/` in your Catapult configuration.

### Software Auto Updates ###

The below table outlines what software is supported for the `software_auto_update` website option. When this option is set to `true`, Catapult manages software core and pluggable component (plugins, modules, etc) updates to the latest compatible versions using the software's CLI tool or similiar method.

Software | `software_auto_update` Support
---------|--------------------------------
`codeigniter2`      | [:white_check_mark:](http://www.codeigniter.com/userguide2/installation/upgrading.html)
`codeigniter3`      | [:white_check_mark:](https://www.codeigniter.com/userguide3/installation/upgrading.html)
`concrete58`        | [:white_check_mark:](https://documentation.concrete5.org/developers/installation/upgrading-concrete5)
`drupal6`           | :white_check_mark:
`drupal7`           | :white_check_mark:
`drupal8`           | :white_check_mark:
`elgg1`             | [:x:](http://learn.elgg.org/en/2.0/admin/upgrading.html)
`elgg2`             | [:x:](http://learn.elgg.org/en/2.0/admin/upgrading.html)
`expressionengine3` | [:x:](https://docs.expressionengine.com/latest/installation/update.html)
`joomla3`           | [:x:](https://docs.joomla.org/J3.x:Updating_from_an_existing_version)
`laravel5`          | [:x:](https://www.laravel.com/docs/master/upgrade)
`mediawiki1`        | [:x:](https://www.mediawiki.org/wiki/Manual:Upgrading)
`moodle3`           | :white_check_mark:
`silverstripe3`     | [:x:](https://docs.silverstripe.org/en/3.4/upgrading/)
`suitecrm7`         | [:x:](https://suitecrm.com/wiki/index.php/Upgrade)
`wordpress4`        | :white_check_mark:
`wordpress5`        | :white_check_mark:
`xenforo1`          | [:x:](https://xenforo.com/help/upgrades/)
`xenforo2`          | :white_check_mark:
`zendframework2`    | :white_check_mark:

In the scenario where an update may overwrite customizations to a file that is expected to be able to be customized (e.g. `.htaccess` or `robots.txt`), you may create an `_append` directory within the repository root of the website with files containing your customizations.

* The append filenames must match the filenames that you would like to append.
* The files must only contain the lines of content that you would like to append.
* Please note that only files that allow for hash style comments (i.e. `# THIS IS A COMMENT`).
* Please note that only files that are in the root of the software are supported.

### HTTPS and Certificates ###

Catapult manages free Domain Validation (DV) certificates compliments of Cloudflare and Let's Encrypt automatically for all of your websites and optionally manages purchased certificates.

It's important to note that certificates are not dependent on protocols. Many vendors tend to use the phrase "SSL/TLS certificate", it may be more accurate to call them "certificates for use with SSL and TLS", since the protocols are determined by your server configuration, not the certificates themselves. It's likely you will continue to see certificates referred to as SSL certificates because at this point that’s the term more people are familiar, however, we're just calling them "certificates".

**Browser Compatibility**

Catapult tracks Mozilla's Operations Security (OpSec) team Security/Server Side TLS recommendations document and the "Intermediate" recommended configuration and is our objective to maintain at least an A rating with [Qualys Labs](https://www.ssllabs.com/ssltest/analyze.html?d=devopsgroup.io&latest). An important note is that Catapult does not support old browsers that do not support Server Name Indication (SNI). Here is Catapult's list of oldest compatible browsers:

* Chrome 1
* Internet Explorer 7 / Windows Vista
* Internet Explorer 8 / Windows 7
* Firefox 1
* Safari 1

**Purchased Certificates**

Depending on your compliance needs you may need to purchase custom certificates unique to your orginization. Below is a table of the three different types of certificates that should be taken into account when auditing your compliance needs.

Feature                                        | Domain Validation (DV certificates)                                                          | Organization Validation (OV certificates)                                                   | Extended Validation (EV certificates)
-----------------------------------------------|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------
Single Domain Certificate                      | :white_check_mark:                                                                           | :white_check_mark:                                                                          | :white_check_mark:
Wildcard Certificate                           | :white_check_mark:                                                                           | :white_check_mark:                                                                          | :x:
Multiple Domain Certificate                    | :white_check_mark:                                                                           | :white_check_mark:                                                                          | :white_check_mark:
Cost                                           | $                                                                                            | $$                                                                                          | $$$
Issuing Process                                | Automatic                                                                                    | Application vetted by Certificate Authority                                                 | Application vetted by Certificate Authority
Issuing Criteria: Domain Name(s) Ownership     | :white_check_mark:                                                                           | :white_check_mark:                                                                          | :white_check_mark:
Issuing Criteria: Organization Existence       | :x:                                                                                          | :white_check_mark:                                                                          | :white_check_mark:
Issuing Criteria: Organization Legal Existence | :x:                                                                                          | :x:                                                                                         | :white_check_mark:
Industry Accepted Issuing Standard             | :x:                                                                                          | :x:                                                                                         | [CAB EV SSL Certificate Guidelines](https://cabforum.org/extended-validation/)
Standard Browser Padlock                       | :white_check_mark:                                                                           | :white_check_mark:                                                                          | :x:
Greenbar Browser Padlock                       | :x:                                                                                          | :x:                                                                                         | :white_check_mark:
Browser Compatibility                          | Google Chrome 1+, Mozilla Firefox 1+, Internet Explorer 5+                                   | Google Chrome 1+, Mozilla Firefox 1+, Internet Explorer 5+                                  | Google Chrome 1+, Mozilla Firefox 3+, Internet Explorer 7+

Catapult optionally manages custom certificates purchased and issued by a Certificate Authority. The following files are required for Catapult to detect and use the custom certificate:

* A bundled file that contains the Root Certificate Authority (CA) certificate and any Intermediate Certificate Authority certificates
    * CA root and intermediate certificate files can be combined like this `cat COMODORSADomainValidationSecureServerCA.crt COMODORSAAddTrustCA.crt AddTrustExternalCARoot.crt >> example_com.ca-bundle`
* The certificate file
* The Certificate Signing Request (CSR) including the CSR file and private key file
    * Generated with `openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr`
    * Your Certificate Signing Request file
    * Your private key file

Here is an example of a certificate implemenation for example.com:

* `reporoot/_cert/example_com/example_com.ca-bundle`
* `reporoot/_cert/example_com/example_com.crt`
* `reporoot/_cert/example_com/server.csr`
* `reporoot/_cert/example_com/server.key`

Here is an example of a certificate implemenation for dev.example.com:

* `reporoot/_cert/dev_example_com/dev_example_com.ca-bundle`
* `reporoot/_cert/dev_example_com/dev_example_com.crt`
* `reporoot/_cert/dev_example_com/server.csr`
* `reporoot/_cert/dev_example_com/server.key`

**Note:** If you have a wildcard certificate, duplicate each environment directory and use the same set of files

### Forcing www ###

Forcing www is generally software specific, unlike forcing the https protocol, which is environment specific and driven by the `force_https` option. To force www ([why force www?](http://www.yes-www.org/)), please follow the respective guides per `software` below.

For `software` that does not have specific documentation, please follow this generic `.htaccess` approach http://stackoverflow.com/a/4958847/4838803

Software | Approach | Documentation
---------|----------|--------------
`codeigniter2`      | `.htaccess`          |
`codeigniter3`      | `.htaccess`          |
`concrete58`        | `.htaccess`          |
`drupal6`           | `.htaccess`          |
`drupal7`           | `.htaccess`          |
`drupal8`           | `.htaccess`          |
`elgg1`             |                      |
`expressionengine3` |                      |
`joomla3`           |                      |
`laravel5`          |                      |
`mediawiki1`        |                      |
`moodle3`           |                      |
`silverstripe3`     | `mysite/_config.php` | http://api.silverstripe.org/3.1/class-Director.html -> http://stackoverflow.com/a/26865882
`suitecrm7`         |                      | 
`wordpress4`        | Database             | http://codex.wordpress.org/Changing_The_Site_URL
`wordpress5`        | Database             | http://codex.wordpress.org/Changing_The_Site_URL
`xenforo1`          |                      |
`xenforo2`          |                      |
`zendframework2`    |                      |

### Debug Output ###

Debug output, unlike logging, is a configuration that outputs exceptions on-screen of your website while you're developing in LocalDev for convenience. It also aligns with the testing activies as defined in [Release Management](#release-management). Debug output is configured at two levels; PHP and software specific, the below chart provides a breakdown.

| LocalDev | Test | QC | Production
|----------|------|----|-----------
| Verbose | Verbose | Hidden | Hidden


### Cache Busting ###

Caching plays a very important role in the performance of your website and enforces and recommends many [performance optimizations](#performance). Catapult generally enforces caching of files to 7 days, because of this, to ensure that a new website release is reflected in a user's browser you should consider [semantic versioning]((http://semver.org/spec/v2.0.0.html)) of website resource files. Here's an example of query string cache busting:

`<link rel="stylesheet" href="/css/style.min.css?v=3.4.1">`

Ready to deploy a new release? Update the version number and the cache will be "busted":

`<link rel="stylesheet" href="/css/style.min.css?v=3.4.2">`

A more complicated, yet effective method of cache busting is by using versioned folders. Resources with a "?" in the URL are not cached by some proxy caching servers. Here is an example of URL path cache busting:

`<link rel="stylesheet" href="/css/3.4.1/style.min.css">`

Ready to deploy a new release? Update the version number and the cache will be "busted":

`<link rel="stylesheet" href="/css/3.4.2/style.min.css">`

Each software type will vary as to the standard convention of website resource file versioning, here is a [Wordpress example](https://wordpress.stackexchange.com/a/90824) to get you started.

### Progressive Web App ###
Progressive Web App (PWA), in general, is a term used to denote web apps that use the latest web technologies. Catapult allows a `manifest.json` file to be placed in your `webroot`. Note that this will be accessible regardless of whether or not you are using the `force_auth` option, which is necessary because `manifest.json` is sometimes accessed outside of the session under which you authenticated. Don't forget to include the `link` tag `<link rel="manifest" href="/manifest.json">` to notify the browser of your manifest. More information regarding PWAs can be found at Google's [Web App Manifest](https://developers.google.com/web/fundamentals/engage-and-retain/web-app-manifest/) and [Progressive Web App Checklist](https://developers.google.com/web/progressive-web-apps/checklist).

### Email ###

Email delivery is an art, there are many considerations when trying to get an email into someone's inbox. Some considerations include, IP reputation, bounce management, analytics visibility, and more. For that reason, Catapult requires setup of a SendGrid account and configuration of SMTP within your website's software. To configure SendGrid with your website's software, please set the SMTP configuration to the following:

* SMTP host: `smtp.sendgrid.net`
* SMTP port: `587`
* Encryption: `TLS`
* Authenticaion: `yes`
* Username: `~/secrets/configuration.yml["company"]["sendgrid_username"]`
* Password: `~/secrets/configuration.yml["company"]["sendgrid_password"]`

An example of implementation would be the [WP Mail SMTP](https://wordpress.org/plugins/wp-mail-smtp/) WordPress plugin.

**Bounce Management**

* With SendGrid: Catapult automatically configures SendGrid to forward bounces to your `~/secrets/configuration.yml["company"]["email"]` to clear hard bounces every 5 days and soft bounces every 3 days.
* Without SendGrid: Postfix will retry sending every hour for five days. Catapult cron looks for bounces and emails them to your `~/secrets/configuration.yml["company"]["email"]` daily.

### Upload Limits ###

The following HTTP request limits are defined for all websites:

**HTTP (ModSecurity) Limits**

* Maximum request body size excluding the size of any files being transported in the request (`SecRequestBodyNoFilesLimit`): `128 KB`
   * Limits the `application/x-www-form-urlencoded` Content-Type
* Maximum request body size (`SecRequestBodyLimit`): `64 MB`
   * Limits the `multi-part` Content-Type
   
**PHP Limits**

* Maximum size of an uploaded file (`upload_max_filesize`): `16 MB`
* Maximum size of post data allowed (`post_max_size`): `64 MB`

**Troubleshooting**

If you are experiencing `401` or `413` HTTP response codes it may be due to the HTTP client not supporting the HTTP 1.1 `Expect` header. This header essentially says "I've got a huge payload, but before I send it please let me know if you can handle it". This gives the endpoints time to renegotiate the client certificate before the payload is sent. The `SSLRenegBufferSize` is set to `128 KB` for security reasons, so if your payload exceeds this size it will fail if the client does not support the HTTP 1.1 `Expect` header. Read more [here](https://stackoverflow.com/questions/14281628/ssl-renegotiation-with-client-certificate-causes-server-buffer-overflow/15394058#15394058).

### Database Migrations ###

The best way to handle changes to the software's database schema is through a migrations system. Database migrations are software specific and are invoked via Catapult for you, here we outline the specifics:

Software | Tool | Command | Documentation
---------|------|---------|--------------
`codeigniter2`      | Migrations      | `php index.php migrate`                                | https://ellislab.com/codeigniter/user-guide/libraries/migration.html
`codeigniter3`      | Migrations      | `php index.php migrate`                                | https://www.codeigniter.com/user_guide/libraries/migration.html
`concrete58`        | Symfony         | `concrete5 migrations:migrate`                         | https://symfony.com/doc/current/bundles/DoctrineMigrationsBundle/index.html
`drupal6`           | Drush           | `drush updatedb -y`                                    | https://www.drupal.org/node/150215
`drupal7`           | Drush           | `drush updatedb -y`                                    | https://www.drupal.org/node/150215
`drupal8`           | Drush           | `drush updatedb -y`                                    | https://www.drupal.org/docs/8/api/update-api/introduction-to-update-api-for-drupal-8
`elgg1`             |                 |                                                        |
`expressionengine3` |                 |                                                        |
`joomla3`           |                 |                                                        |
`laravel5`          | Migrations      | `php artisan migrate`                                  | https://laravel.com/docs/5.0/migrations
`mediawiki1`        | UpdateMediaWiki | `php maintenance/update.php`                           | https://www.mediawiki.org/wiki/Manual:Update.php
`moodle3`           |                 |                                                        |
`silverstripe3`     | MigrationTask   | `php framework/cli-script.php dev/tasks/MigrationTask` | http://api.silverstripe.org/3.3/class-MigrationTask.html
`suitecrm7`         |                 |                                                        |
`wordpress4`        | WP-CLI          | `wp-cli core update-db`                                | http://codex.wordpress.org/Creating_Tables_with_Plugins#Adding_an_Upgrade_Function
`wordpress5`        | WP-CLI          | `wp-cli core update-db`                                | http://codex.wordpress.org/Creating_Tables_with_Plugins#Adding_an_Upgrade_Function
`xenforo1`          |                 |                                                        |
`xenforo2`          |                 |                                                        |
`zendframework2`    |                 |                                                        |

### Refreshing Databases ###

* Databases are dumped once per day to the `~/_sql` folder and restored, dependent on the environment and `software_workflow` setting per website - see [Release Management](#release-management) for details.
* Leverage Catapult's workflow model (configured by `software_workflow`) to trigger a database refresh. From the develop branch, commit a deletion of today's database backup lock file from the `~/_sql` folder.

### Connecting to Databases ###

Oracle SQL Developer is the recommended tool, to connect to and work with, databases. It is free, commercially supported, cross-platform, and supports multiple database types.

* **Download and install** [Oracle SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/index.html), some platforms require the [Java SE Development Kit](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
* **Install third party JDBC drivers**: Oracle SQL Developer uses JDBC, via a .jar file, to connect to different database types. To install a new JDBC connector, download the respective .jar file then from Oracle SQL Developer > Preferences > Database > Third Party JDBC Drivers, click Add Entry.<sup>[4](#references)</sup>
    * **MySQL** http://dev.mysql.com/downloads/connector/j/5.0.html
        * For convenience, you may also use `~/catapult/installers/mysql-connector-java-5.0.8-bin.jar`
    * **MSSQL** https://sourceforge.net/projects/jtds/files/jtds/
        * For convenience, you may also use `~/catapult/installers/jtds-1.3.1.jar`
* **Connecting to:** LocalDev
    * The firewall allows direct connection to the database server. 
        * From Oracle SQL Developer > View > Connections, add a New Connection with the respective environment's mysql user values in `~/secrets/configuration.yml`.
* **Connecting to:** Test, QC, Production
    * The firewall does not allow direct connect to the database servers.
        * From Oracle SQL Developer > View > SSH, add a New SSH Host in Oracle SQL Developer with the respective environment's web server host public ip address, root username with key file at `~/secrets/id_rsa`.
            * Create a New Local Port Forward with the respective environment's database server host private ip address and port 3306.
        * From Oracle SQL Developer > View > Connections, add a New Connection with the respective environment's mysql user values in `~/secrets/configuration.yml`.
            * The hostname will be localhost since we are forwarding the port through our local SSH tunnel.

### Production Hotfixes ###

Always weigh the risk of *not performing* a production hotfix versus *performing* it, as production hotfixes require going outside of the normal development and testing workflow. Below is an example of how you can determine severity:

Ask key stakeholders the following questions and assign a 1 or 0 for the answer, then add up the total:

* What is the organizational risk?
    * High = 1 or Low = 0
* How many users does this effect?
    * Many = 1 or Few = 0
* Is there a workaround?
    * No = 1 or Yes = 0
* What is the user impact?
    * High = 1 or Low = 0

The total will determine the level of severity, typically a 4 would be considered a candidate for a production hotfix:

* 0=Tolerate
* 1=Trivial
* 2=Minor
* 3=Major
* 4=Critical

Performing a production hotfix varies depending on the website's `software` type, `software_workflow` direction, and type of change (code or database).

* `software_workflow: downstream`
    * **Code**
        1. In `~/configuration.yml`, temporarily set the environments -> dev -> branch key to `branch: master`, and do not commit the change
        2. Provision any related LocalDev servers
        3. Develop, test, then commit any changes directly to the `master` branch
        4. Run the Production Bamboo build and verify the release
        5. Create a pull request and merge the `master` branch into the `develop` branch
        6. Set the environments -> dev -> branch key back to `branch: develop`
        7. Provision any related LocalDev servers
    * **Database**
        * Login to the Production website and make the change
            * (any database change that is beyond the direct capability of the `software` should not be taken out as a production hotfix)
* `software_workflow: upstream`
    * **Code**
        1. In `~/configuration.yml`, temporarily set the environments -> dev -> branch key to `branch: master`, and do not commit the change
        2. Provision any related LocalDev servers
        3. Develop, test, then commit any changes directly to the `master` branch
        4. Run the Production build and verify the release
        5. Create a pull request and merge the `master` branch into the `develop` branch
        6. Set the environments -> dev -> branch key back to `branch: develop`
        7. Provision any related LocalDev servers
    * **Database**
        1. Login to the Production *and* Test website and make the change
            * (any database change that is beyond the direct capability of logging into the `software` and safely making the change, should not be taken out as a production hotfix)
        2. From LocalDev and the `develop` branch of the website's repository, commit a deletion of today's (if exists) SQL dump file from within the `~/sql` folder
            * (this ensures there is a known committed SQL dump of your change to the `develop` branch for when this branch is merged upstream)
        3. From LocalDev, temporarily checkout the `master` branch of the website's repository, make your change in the most recent SQL dump file from within the `~/sql` folder
            * (this ensures that during the next Production build your change is not overwritten)



## Automated Deployment Cycle ##

The automated deployment cycle releases changesets merged into respective environment branches for websites and your Catapult configuration, in addition to running server updates.

Environment | Scheduled
----------- | ---------
LocalDev    | n/a, requires provision
Test        | 12:00 AM
QC          | 1:00 AM
Production  | 2:00 AM

* Operating System and server software updates
* [Website software updates](#software-auto-updates)
* [Website repository changesets](#software-workflow)
* [Website software database restores](#software-workflows)
* [Website software database migrations](#database-migrations)
* [Website software database backups](#software-workflows)



## Maintenance Cycle ##

A maintenance cycle is scheduled for defined times within the timezone that is defined within `~/secrets/configuration.yml` at the `timezone_redhat` and `timezone_windows` value of the [Company](#company) entry. This ensures system and website software is patched and other security controls are run within your infrastructure to automatically mitigate security vulnerabilites.

### Daily ###
Daily maintenance occurs:

* Red Hat - 3:05 AM
* Windows - 2:00 AM

Daily maintenance includes:

* Updating Operating System and server software
* Rotating logs
* Discovering mail which has failed to send

### Weekly ###

Weekly maintenance occurs:

* Red Hat - Sunday 3:25 AM
* Windows - Sunday 3:00 AM

Weekly maintenance includes:

* [Security Preventive Controls](#preventive-controls)
* [Security Detective Controls](#detective-controls)
* [Security Corrective Controls](#corrective-controls)
* [Auto-rewew HTTPS certificate](#https-and-certificates)
* Git garbage collection for website repositories
* Performing database maintenance

Servers will be rebooted when:

* Red Hat - a kernel update is staged
* Windows - Microsoft Update indicates a restart is required



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
        * Note: The Production database is overwritten and restored from the latest sql dump file from Test in the `~/_sql` folder.
* `software_workflow: downstream`
    * Files
        * Reverse the offending merge commit from the master branch and run the Production deployment.
    * Database
        * Reverse the offending database dump auto-commit from the develop branch and manually restore the Production database from the desired sql dump file in the `~/_sql` folder.
        * Note: The Production database is dumped once per day when the production build is run.



# Security #

Catapult enforces many security best practices that are important for you to be aware of and understand. These controls avoid, detect, counteract, or minimize security risks to the platform and visitors. The [Lynis](https://cisofy.com/lynis/) security auditing tool is used to evaluate and harden configuration of the system.

## Preventive Controls ##

**Edge**

* \*DDoS protection
* \*Bad browser
* \*Bad IP from Project Honeypot and Cloudflare's Threat Score list

**Server**

* Hardened kernel and network interface configuration
* Hardened SSH configuration including key-only authentication
* Strict firewall ruleset
* Automatic weekly kernel updates

**Application**

* [OWASP ModSecurity Core Rule Set (CRS)](https://www.owasp.org/index.php/Category:OWASP_ModSecurity_Core_Rule_Set_Project) Apache rules
* [Mozilla OpSec](https://wiki.mozilla.org/Security/Server_Side_TLS) strict HTTPS protocol and cipher suite
* [OWASP Secure Headers Project](https://www.owasp.org/index.php/OWASP_Secure_Headers_Project#tab=Headers) recommended HTTP response headers
* Automatic hourly application updates

**Software**

* Strict directory and file permissions
* Automatic software updates during a build

\* This security feature only takes effect when the website's nameservers are set to CloudFlare

## Detective Controls ##

* ARPwatch (Address Resolution Protocol) notifies of changed MAC/IP pairings
* Fail2Ban filters for sshd, sshd-ddos, and apache-botsearch
* SysStat collects and stores system performance and usage activity
* Weekly report of 404s and error keywords targeteted at the server and virtual hosts

## Corrective Controls ##

* Weekly ClamAV antivirus scan of website files

## Data Protection ##

Catapult introduces many best practice data protection measures, however, security of personal data is ultimately your responsibility. Generally speaking, if personal information is compromised, you are required by law to notify the party. Laws vary country-by-country and state-by-state, and can be enforcable in the state or country where the individual is physically located when the data is collected. This means that, even if your website is hosted within the U.S., you could potentially be subject to another country's data protection laws. The main principles of data protection, include:

* Privacy by design
* Right to access
* Right to be forgotten
* Data portability
* Breach notification

### United States ###

Personally identifiable information (PII), in the U.S., is generally classified as **an individual's first and last name in combination with a Social Security number, driver's license number, or financial account number**. For more information, please see [this list](http://www.itgovernanceusa.com/data-breach-notification-laws.aspx) of data breach laws by U.S. state compiled by IT Governence.

### Europe ###

The General Data Protection Regulation (GDPR) is a regulation in E.U. law on data protection and privacy for all individuals within the European Union that becomes enforceable starting May 25, 2018. Article 4(1) of the GDPR defines "personal data" as any information relating to an identified or identifiable natural person ('data subject'); an identifiable natural person is one who can be identified, directly or indirectly, in particular by reference to an identifier such as a name, an identification number, location data, an online identifier or to one or more factors specific to the physical, physiological, genetic, mental, economic, cultural or social identity of that natural person. For more information, please see the [GDPR](http://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32016R0679).


# Compliance #

There are many complex compliance and audit standards that are your responsibility to understand and execute. Each Catapult instance is independant to you - including the required services that you signed up for during [Services Setup](#services-setup).

## Cloud Compliance ##

Security **of** the cloud. This is the responsibility of the cloud service.

Service           | Catapult Context                         | SOC 1                                                              | SOC 2                                                              | SOC 3
------------------|------------------------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------
AWS EC2 US EAST   | Windows server hosting                   | [:white_check_mark:](https://aws.amazon.com/compliance/soc-faqs/)  | [:white_check_mark:](https://aws.amazon.com/compliance/soc-faqs/)  | [:white_check_mark:](https://aws.amazon.com/compliance/soc-faqs/)
BitBucket         | Repository hosting                       | [:white_check_mark:](https://www.atlassian.com/cloud/security/)    |                                                                    |
DigitalOcean NYC3 | Red Hat and Bamboo server hosting        |                                                                    | [:white_check_mark:](https://www.digitalocean.com/help/policy/)    | [:white_check_mark:](https://www.digitalocean.com/help/policy/)
GitHub            | Repository hosting                       |                                                                    |                                                                    |
New Relic         | Server communication, log files          |                                                                    | [:white_check_mark:](http://newrelic.com/why-new-relic/security)   |

## Self Compliance ##

Security **in** the cloud. This is your responsibility, however, the underlying service must have basic support for the compliance scenario.

Service           | Catapult Context                         | HIPAA BAA                                                                 | PCI DSS Level 1
------------------|------------------------------------------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------
AWS EC2 US EAST   | Windows server hosting                   | [:white_check_mark:](https://aws.amazon.com/compliance/hipaa-compliance/) | [:white_check_mark:](https://aws.amazon.com/compliance/pci-dss-level-1-faqs/)
CloudFlare (Pro)  | Web application firewall                 |                                                                           | [:white_check_mark:](https://support.cloudflare.com/hc/en-us/articles/202249734-CloudFlare-and-PCI-Compliance)
BitBucket         | Repository hosting                       | [:x:](https://www.atlassian.com/security/security-faq/)                   |
DigitalOcean NYC3 | Red Hat and Bamboo server hosting        | [:question:](https://www.digitalocean.com/help/policy/)                   | [:question:](https://www.digitalocean.com/help/policy/)
GitHub            | Repository hosting                       | [:question:](https://help.github.com/articles/github-security/)           |

See an error or have a suggestion? Email security@devopsgroup.io if confidential or submit a pull request - we appreciate all feedback.



# Performance #

Your website's performance is maximized with bandwidth, caching, and geographic optimizations. Catapult enforces these throughout every layer of your website, all in an effort to improve page loading times. Below is an example of the great performance gain of when page caching and CSS/JS aggregation are enabled for a Drupal website - all of which is managed by Catapult.

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_performance.png" alt="Catapult Performance">

**Please note:** Any optimization that would impact development or component testing in LocalDev is disabled; this workflow aligns with the testing activites described in the [Release Management](#release-management) section.

## Bandwidth Optimizations ##

Bandwidth optimizations are made to lower the total bytes downloaded and decrease the amount of requests made by the browser.

* HTTP Content-Encoding headers are set for a defined list of files, this will compress the output sent with gzip. This saves network bandwidth.
* Aggregating CSS files and JavaScript files is enabled for the website's software type if available.
  * [https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/software_operations_meta.sh](https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/software_operations_meta.sh)

## Caching Optimizations ##

Caching is enabled for many layers of your website including storing pre-interpreted PHP in memory, storing page caches for certain software types, and storing files on visitor's local disk.

* Zend OPcache is enabled for faster PHP execution through opcode caching and optimization.
  * [https://secure.php.net/manual/en/intro.opcache.php](https://secure.php.net/manual/en/intro.opcache.php)
* Page caching is enabled for the website's software type if available.
  * [https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/software_operations_meta.sh](https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/software_operations_meta.sh)
* HTTP Cache-Control headers are set to expire browser cached files after a default of 7 days; longer for specific file types.
  * [https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/apache_vhosts.sh](https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/apache_vhosts.sh)
* HTTP ETag headers are set for all files, the ETag is a unique value based on the files modified time and size in bytes. If the ETag value is unchanged then a cached version is served if available. This saves network bandwidth.
  * [https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/apache_vhosts.sh](https://github.com/devopsgroup-io/catapult/blob/master/provisioners/redhat/modules/apache_vhosts.sh)

## Geographic Optimizations ##

Shortening the physical distance between the server and visitor can trim priceless milliseconds from page loading time. (One might use this as an argument as to why browser caching and your overall caching strategy is so important.)

* If your website's name servers are set to Cloudflare, you will take advantage of files being cached accross their global network, bringing it closer to visitors from every region.
  * [https://support.cloudflare.com/hc/en-us/articles/200172516-Which-file-extensions-does-Cloudflare-cache-for-static-content-](https://support.cloudflare.com/hc/en-us/articles/200172516-Which-file-extensions-does-Cloudflare-cache-for-static-content-)

## Recommended Optimizations ##

Catapult as a platform can only reach so far into the configuration of your website's software. Here are a few recommended development practices that will improve the performance of your website:

* Use a development task automation tool, like [Gulp](http://gulpjs.com/) to perform the following:
  * Image compression with [imagemin](https://www.npmjs.com/package/gulp-imagemin)
  * JavaScript minification with [UglifyJS2](https://www.npmjs.com/package/gulp-uglify)
  * CSS minification with [clean-css](https://www.npmjs.com/package/gulp-clean-css)
* Execute `<script>` tags [asynchronously](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-async)
    * Note that asynchronous scripts are not guaranteed to execute in specified order
* Execute `<script>` tags after the document has been parsed with [defer](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-defer)
    * Note this is the same as placing script tags just before the `</body>` tag
* Use [CSS sprites](https://css-tricks.com/css-sprites/) to reduce the number of HTTP requests
* Take advantage of [link prefetching](https://css-tricks.com/prefetching-preloading-prebrowsing/) using `rel="prefetch"`
* Write [PHP the right way](http://www.phptherightway.com/#welcome)
  * Practice [self-documenting code](https://www.amazon.com/dp/0132350882/)
* Write [efficient PHP](http://www.phpbench.com/)

Google's [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/) is a good tool to test for performance optimizations.



# Performance Testing #

Often disregarded, performance testing is a crucial component of quality assurance. The risks of neglecting performance testing include downtime, SEO impacts, gaps in analytics, poor user experience, and unknown ability to scale.

With Catapult's exactly duplicated configuration, even the Test environment can accurately represent the performance potential of the Production environment. [ApacheBench](https://httpd.apache.org/docs/2.4/programs/ab.html) is a powerful tool to test request performance and concurrency - OSX includes ApacheBench out of the box, while [this StackOverflow post](http://stackoverflow.com/a/7407602/4838803) details how to get up and running on Windows.

ApacheBench enables us to profile request performance (`-n` represents the number of requests to perform) and concurrency (`-c` represents the number of multiple requests to make at a time) to test for performance, including common limits such as [C10k and C10M](http://highscalability.com/blog/2013/5/13/the-secret-to-10-million-concurrent-connections-the-kernel-i.html).

## Website Concurrency Maximum ##

Using a website with historical Google Analytics data, access the Audience Overview and find the busiest Pageview day from the past 30-days and then drill into that date. Find the hour with the most Pageviews, then the accompanying Avg. Session Duration. Using the following formula, we are able to find the Concurrency Maxiumum.

*(Pageviews x Avg. Session Duration in seconds) / 3,600 seconds* = **Concurrency Maxiumum**

<img src="https://cdn.rawgit.com/devopsgroup-io/catapult/master/catapult/installers/images/catapult_website_concurrency_maximum.png" alt="Catapult Website Concurrency Maximum">

**365,000 pageviews per month**

Take a website with an average of 500 pageviews per hour, or 365,000 pageviews per month, which has a busiest hour of 1,000 pageviews.

Pageviews | Avg. Session Duration | Total Session Seconds | Concurrency Maxiumum
----------|-----------------------|-----------------------|---------------------
1,000 | 60 minutes (3,600 seconds) | 3,600,000 | **1,000**
1,000 | 10 minutes (600 seconds) | 600,000 | **166**
1,000 | 5 minutes (300 seconds) | 300,000 | **88**
1,000 | 1 minute (60 seconds) | 60,000 | **16**

*100 concurrent requests performed 10 times*
```
ab -l -r -n 1000 -c 100 -H "Accept-Encoding: gzip, deflate" http://test.drupal7.devopsgroup.io/
```

**14,600 pageviews per month**

Take a website with an average of 20 pageviews per hour, or 14,600 pageviews per month, which has a busiest hour of 100 pageviews.

Pageviews | Avg. Session Duration | Total Session Seconds | Concurrency Maxiumum
----------|-----------------------|-----------------------|---------------------
100 | 60 minutes (3,600 seconds) | 36,000 | **1,000**
100 | 10 minutes (600 seconds) | 60,000 | **16**
100 | 5 minutes (300 seconds) | 30,000 | **8**
100 | 1 minute (60 seconds) | 6,000 | **1.6**

*10 concurrent requests performed 10 times*
```
ab -l -r -n 100 -c 10 -H "Accept-Encoding: gzip, deflate" http://test.drupal7.devopsgroup.io/
```

## Interpreting Apache AB Results ##

Using a satisifed [Apdex](https://en.wikipedia.org/wiki/Apdex) of 7 seconds, we can see that 98% of users would be satisfied.

```
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
```



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

As part of a new release, the version number in `~/VERSION.yml` will be incremented and git tagged with the same version number along with a [GitHub Release](https://help.github.com/articles/about-releases/).



# Community #



## Partnerships ##

The Catapult team values partnerships and continuous improvement.

* [06-03-2016] New Relic creates request on Catapult's behalf for a free entry point for the New Relic Synthetics API
* [01-28-2016] Pantheon provides feedback
* [01-22-2016] New Relic provides private beta access to their Synthetics API along side Breather, Carfax, Ring Central, Rackspace, and IBM.



## Conferences ##

Catapult is making the conference tour! We plan to attend the following conferences, with more to come. Get a chance to see Catapult in action, presented by it's core developers.

* Spring 2016 [04-08-2016] [Drupaldelphia](http://drupaldelphia.com/): DevOps Discipline: Detailed and Complete



## Meetups ##

Catapult will also be seen throughout local meetups in the Philadelphia and Greater Philadelphia area! Get a chance to meet the team and engage at a personal level.

* [Technical.ly Philly](http://www.meetup.com/Technically-Philly/) 9k+ technologists
* [Tech in Motion Philly](http://www.meetup.com/TechinMotionPhilly/) 7k+ technologists
* [Philadelphia WordPress Meetup Group](http://www.meetup.com/philadelphia-wordpress-meetup-group/) 2k+ technologists
* [Philly DevOps](http://www.meetup.com/PhillyDevOps/) 2k+ technologists
    * [\[09-20-2016\]  From Pets to Serverless: Deployment Panel](https://www.meetup.com/PhillyDevOps/events/232930398/)
* [Greater Philadelphia Drupal Meetup Group](http://www.meetup.com/drupaldelphia/) .75k+ technologists



# References #
1. Atlassian. Comparing Workflows. https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow. Accessed February 15, 2016.
2. Pantheon. Load and Performance Testing: Before You Begin. https://pantheon.io/docs/articles/load-and-performance-testing/. Accessed February 20, 2016.
3. Acquia. Acquia Dev Desktop. https://www.acquia.com/products-services/dev-desktop. Accessed February 20, 2016.
4. Oracle Technology Network. Oracle SQL Developer Migrations: Getting Started. http://www.oracle.com/technetwork/database/migration/omwb-getstarted-093461.html#conf. Accessed March 14, 2016.
