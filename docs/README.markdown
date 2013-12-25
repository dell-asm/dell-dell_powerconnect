# Dell PowerConnect switch module

**Table of Contents**

- [Dell PowerConnect switch module](#Dell-PowerConnect-switch-module)
	- [Overview](#overview)
	- [Features](#features)
	- [Requirements](#requirements)
	- [Usage](#usage)
		- [Device Setup](#device-setup)
		- [PowerConnect operations](#PowerConnect-operations)

## Overview
The Dell PowerConnect switch module is designed to extend the support for managing PowerConnect switch configuration using Puppet and its Network Device functionality.

The Dell PowerConnect switch module has been written and tested against the following Dell PowerConnect switch models:
- PowerConnect 7024 (firmware version 5.1.2.3). 
However, this module may be compatible with other versions.

## Features
This module supports the following functionality:

 * VLAN creation and deletion.
 * Interface Configuration
 * Port Channel Configuration
 * Applying Configuration Updates on Switch
 * Applying Firmware Upgrades on Switch

## Requirements
As a Puppet agent cannot be directly installed on the PowerConnect switch, it can either be managed from the Puppet Master server,
or through an intermediate proxy system running a puppet agent. The requirements for the proxy system are as under:

 * Puppet 2.7.+

## Usage

### Device Setup
To configure a PowerConnect, the device *type* must be `dell_powerconnect`.
The device can either be configured within */etc/puppet/device.conf*, or, preferably, create an individual config file for each device within a sub-folder.
This is preferred as it allows the user to run the puppet against individual devices, rather than all devices configured...

In order to run the puppet against a single device, you can use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/powerconnect.example.com.conf`:

    [powerconnect.example.com]
      type dell_powerconnect
      url telnet://admin:P@ssw0rd@powerconnect.example.com/?enable=P@ssw0rd

### PowerConnect operations
This module can be used to configure vlans, interfaces and port-channels on PowerConnect switch.
For example: 


node "powerconnect.example.com" {
	powerconnect_vlan{
		'9':
			vlan_name => 'VLAN009',
			ensure => present;
		'10':
			vlan_name => 'VLAN010',
			ensure => present;
	}
}

This creates two VLANs 9 and 10 on the PowerConnect switch, with their respective descriptions.

You can also use any of the above operations individually, or create new defined types, as required. The details of each operation and parameters 
are mentioned in the following readme files, that are shipped with the module:

  - vlan_create_remove.md
  - interface_configure.md
  - portchannel_tag_untag_vlans.md
  - configuration_apply.md
  - firmware_upgrade.md

