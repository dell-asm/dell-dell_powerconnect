require 'puppet_x/dell_powerconnect/model/model_value'
require 'puppet_x/dell_powerconnect/model/switch'
require 'puppet_x/dell_powerconnect/model/interface'
require 'puppet_x/dell_powerconnect/model/portchannel'

module PuppetX::DellPowerconnect::Model::Switch::Base
  def self.register(base)

    base.register_model(:vlan, PuppetX::DellPowerconnect::Model::Vlan, /^(\d+)\s\S+/, 'show vlan')
    base.register_model(:interface, PuppetX::DellPowerconnect::Model::Interface, /^interface\s+(\S+)\r*$/, 'show running-config')
    base.register_model(:portchannel, PuppetX::DellPowerconnect::Model::Portchannel, /^interface(\s)+port-channel(.+)$/, 'show running-config')

  end
end
