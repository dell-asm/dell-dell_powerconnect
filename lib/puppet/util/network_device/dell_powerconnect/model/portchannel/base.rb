require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/portchannel'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\sport-channel\s+(\S+).*?)^!/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      after :description
      add do |transport, value|
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{base_command} #{old_value}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)    
    ifprop(base, :allowvlans) do
      match /^\s*switchport trunk allowed vlan \S*$/
      add do |transport, value|
        transport.command("switchport mode trunk")
        transport.command("switchport trunk allowed vlan add #{value}")
      end
      remove { |*_| }
    end
    ifprop(base, :removevlans) do
      add do |transport, value|
        transport.command("switchport mode trunk")
        transport.command("switchport trunk allowed vlan remove #{value}")
      end
      remove { |*_| }
    end
  end
end
