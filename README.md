# websphere_deployer

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with websphere_deployer](#setup)
    * [What websphere_deployer affects](#what-websphere_deployer-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with websphere_deployer](#beginning-with-websphere_deployer)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Install the `deploymgr` subsystem to `/opt/ibm/deployments` and provide a 
defined resource type to do `ear` file deployments by dropping them into the
`/opt/ibm/deployments/incomming` directory.

Files are only downloaded to the incoming directory if the version number
(obtained by munging the download URL) is different to the version of the
installed appliation.

## Setup

### What websphere_deployer affects

* Directory structure for `/opt/ibm/deployments`
* Installs a cron job to deploy all `.ear` files found in the incoming
  directory (can be disabled)
* Installs custom fact to resolve application name from propeties file
* Installs custom fact to resolve version from application name

### Setup Requirements

* WebSphere must already be installed
* Needs puppet future parser (PE > 3.8)
* Needs an external server to download `.ear` files from
* Properties files (contents of `/opt/ibm/deployments/properties`) should already be on the system
* Requires the [archive module](https://github.com/puppet-community/puppet-archive)

## Usage

### Install the `deploymgr` subsystem:
```puppet
  class { "websphere_deploy": }
```

### Install an ear file from a nexus server

```puppet
  websphere_deployer::deploy_ear { "http://nexus.dev.rms.nsw.gov.au/content/groups/rms-repo/nswrta/opr/opr-ear/4.2.0/opr-ear-4.2.0.ear":
    deployment_instance => "opr",
  }
```

Assuming that either `opr` is either missing or a different version to `4.2.0`,
the above code would download the `.ear` file and save it to the incoming 
directory.

If the version on the system matches the version in the `.ear` file, then no
action will be taken.

Current version is obtained by looking at the `ws_version` fact, which this
module installs.

## Reference

### $::wsapp_instance_appnames
Custom fact to resolve `deployment_instance` to application names.  Obtained
by inspecting every `.properties` file under `/opt/ibm/deployer/properties`.

This path is stored within the custom fact itself and results in a structure
similar to the following:
```ruby
wsapp_instance_appnames => {
  sanctionliftws => "SanctionLiftService EAR",
  sz => "sz EAR",
  ...
}
```

### $::wsapp_versions
Custom fact to resolve application name to version information.  Obtained by 
finding `pom.xml` according to a shell glob defined inside the fact itself.
Results in a structure similar to the following:
```ruby 
wsapp_versions => {
   => {
    groupId => "RMS",
    artifactId => "hello world",
    version => "4.55.6"
  }
}
```

### websphere_deployer
Class to setup `deploymgr` subsystem

### websphere_deployer::deploy_ear
Defined resource type for downloading ear files

## Development
To test custom facts, take a copy of the directory structure from
`/opt/ibm/deployments` on a production machine to your workstation, then run
facter by pointing it at the checked out sourcecode:
```shell
FACTERLIB=PATH_TO_CHECKED_OUT_MODULE/lib/facter/ facter
```

## Testing
This module ships with RSpec tests.  To run them, first prepare your system:
```shell
bundle install
```

You may then run the tests at will.  If downloading from GitHub from behind a
proxy server, you will need to have your `http_proxy` and `https_proxy` 
variables exported
```shell
bundle exec rake spec
```

It is suggested to have your CI server execute these tests before allowing code
to be published to the puppet master

## Limitations
* Puppet Labs do not support or maintain this module
