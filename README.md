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

The Dell PowerConnect switch module has been written and tested against the following Dell PowerConnect switch models. 
However, this module may be compatible with other versions.
- PowerConnect 7024 (firmware version 5.1.2.3). 


## Features
This module supports the following functionality:

 * VLAN creation and deletion
 * Interface Configuration
 * Port Channel Configuration
 * Applying Configuration Updates on Switch
 * Applying Firmware Upgrades on Switch

## Requirements
Because the Puppet agent cannot be directly installed on the PowerConnect switch, the agent can be managed either from the Puppet Master server,
or through an intermediate proxy system running a puppet agent. The following are the requirements for the proxy system:

 * Puppet 2.7.+

## Usage

### Device Setup
To configure a PowerConnect switch, the device *type* specified in `device.conf` file must be `dell_powerconnect`. The device can either be configured within */etc/puppet/device.conf*, or, preferably, create an individual config file for each device within a subfolder.
This is preferred because it allows the user to run the puppet against individual devices, rather than all devices configured.

In order to run the puppet against a single device, you can use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/powerconnect.example.com.conf`:

    [powerconnect.example.com]
      type dell_powerconnect
      url telnet://admin:P@ssw0rd@powerconnect.example.com/?enable=P@ssw0rd

### PowerConnect operations
This module can be used to configure VLANs, interfaces, and port-channels on PowerConnect switch.
For example: 

```
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
```
This creates two VLANs - 9 and 10 on the PowerConnect switch, with their respective descriptions.

See tests folder for additional examples.
