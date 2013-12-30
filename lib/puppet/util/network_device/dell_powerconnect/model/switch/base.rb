require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/model_value'
require 'puppet/util/network_device/dell_powerconnect/model/switch'
require 'puppet/util/network_device/dell_powerconnect/model/interface'
require 'puppet/util/network_device/dell_powerconnect/model/portchannel'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch::Base

  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan, /^(\d+)\s\S+/, 'show vlan')
    base.register_model(:interface, Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Interface, /^interface\s+(\S+)\r*$/, 'sh run')
    base.register_model(:portchannel, Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel, /^interface(\s)+port-channel(.+)$/, 'show run')

  end
end
