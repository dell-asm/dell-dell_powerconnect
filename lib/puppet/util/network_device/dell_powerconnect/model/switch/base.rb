require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/model_value'
require 'puppet/util/network_device/dell_powerconnect/model/switch'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch::Base

  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan, /^(\d+)\s\S+/, 'show vlan')

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c4500'
      base.register_new_module('c4500', 'hardware')
    end

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c2960'
      base.register_new_module('c2960', 'hardware')
    end

  end
end
