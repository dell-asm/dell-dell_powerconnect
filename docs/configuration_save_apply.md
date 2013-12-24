# Dell PowerConnect switch module

## Overview

This module provides a common way to manage configuration of Dell PowerConnect switches. It is based on network_device
utility provided by Puppetlabs.

### Currently implemented/tested Puppet Types

* powerconnect_vlan - add/remove/update VLANs on the switch

### Partially implemented

* powerconnect_interface
* powerconnect_portchannel

### Tested with the following type of switches

* Dell PowerConnect 7024

## Usage

device.conf

    [$switch_fqdn]
    type dell_powerconnect
    url ssh://$user:$pass@$switch_fqdn:$ssh_port/?$flags
    
site.pp (or any puppet manifest file)

	node "$switch_fqdn" {
		powerconnect_vlan{
			'$vlan-id1':
				desc => '$vlan1-desc',
				ensure => present;
			'$vlan-id2':
				desc => '$vlan2-desc',
				ensure => present;
		}
	}

Note: If you want to see the Communication with the Switch append --debug to the Puppet device Command