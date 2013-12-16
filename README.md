# Dell PowerConnect switch module

## Overview

This module provides provides Puppet features to manage configuration of Dell PowerConnect switches. It is based on network_device
module provided by Puppetlabs.

### Currently implemented/tested Puppet Types

* powerconnect_vlan

### Partially implented


### Tested with the following Switchtypes

* Dell PowerConnect 7024

## Usage

device.conf

    [$switch_fqdn]
    type dell_powerconnect
    url ssh://$user:$pass@$switch_fqdn:$ssh_port/?$flags

Note: If you want to see the Communication with the Switch append --debug to the Puppet device Command