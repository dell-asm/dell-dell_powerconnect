require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/vlan'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan::Base

  def self.register(base)
    vlan_scope = /^((\d+)\s+(.*))/
    
    base.register_scoped :ensure, vlan_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show vlan'
      default :absent
      add { |*_| }
      remove { |*_| }
    end
    
    base.register_scoped :desc, vlan_scope do
      match /^\d+\s(\S+)/
      cmd 'show vlan'
      add do |transport, value|
        Puppet.debug "Executing vlan name command with value #{value}"
        transport.command("name #{value}")
        Puppet.debug "Executing vlan name command - completed"
      end
      remove { |*_| }
    end
  end
end
