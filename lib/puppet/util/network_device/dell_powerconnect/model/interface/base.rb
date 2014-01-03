require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/interface'

module Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Interface::Base
  def self.configureinterface(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\s+(\S+).*?)^!/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      after :description
      add do |transport, value|
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{base_command}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)
    configureinterface(base, :description)
    configureinterface(base, :mtu, "mtu")
    configureinterface(base, :mode, "switchport mode")
    configureinterface(base, :add_vlans_general_mode) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :mode
      add do |transport, value|
        transport.command("switchport general allowed vlan add #{value} tagged") do |out|
          out.each_line do |line|
            if line.match(/ERROR:/)
              Puppet.warning "#{line}"
              #raise "#{line}"
            end
          end
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :remove_vlans_general_mode) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/

      after :mode
      add do |transport, value|
        transport.command("switchport general allowed vlan remove #{value}")
      end
      remove { |*_| }
    end
    configureinterface(base, :add_vlans_trunk_mode) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :mode
      add do |transport, value|
        transport.command("switchport trunk allowed vlan add #{value}") do |out|
          out.each_line do |line|
            if line.match(/ERROR:/)
              Puppet.warning "#{line}"
              #raise "#{line}"
            end
          end
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :remove_vlans_trunk_mode) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :mode
      add do |transport, value|
        transport.command("switchport trunk allowed vlan remove #{value}")
      end
      remove { |*_| }
    end
    configureinterface(base, :add_interface_to_portchannel) do
      match do |txt|
        txt.match(/channel-group/) ? :present : :absent
      end
      add do |transport, _|
        transport.command("channel-group #{value} mode active")
      end
      remove do |transport, _|
        transport.command("no channel-group")
      end
    end
    configureinterface(base, :remove_interface_from_portchannel) do
      match /^\s*channel-group\s+(.*?)\s*$/
      add do |transport, value|
        if value == :true
          transport.command("no channel-group")
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :shutdown) do
      match /^\s*shutdown\s+(.*?)\s*$/
      add do |transport, value|
        if value == :true
          transport.command("shutdown")
        end
        if value == :false
          transport.command("no shutdown")
        end
      end
      remove { |*_| }
    end
  end
end
