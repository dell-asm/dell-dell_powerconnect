require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/model_value'
require 'puppet/util/network_device/dell_powerconnect/model/switch'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch::Base

  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan, /^(\d+)\s\S+/, 'show vlan')

  end
end
