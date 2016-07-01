require 'puppet_x/dell_powerconnect/model/portchannel'

module PuppetX::DellPowerconnect::Model::Portchannel::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\sport-channel\s+(\S+).*?)^!/m do
      cmd 'show running-config'
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
    ifprop(base, :switchport_mode, "switchport mode") do
      match /switchport mode ([\w-]+)/
      add do |transport, value|
        transport.command("switchport mode #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :shutdown) do
      match /shutdown/
      add do |transport, value|
        if value == :true
          transport.command("shutdown")
        end
        if value == :false
          transport.command("no shutdown")
        end
      end
      remove { |*_|}
    end

    ifprop(base, :tagged_general_vlans) do
      match /^\s*switchport general allowed vlan \S*$/
      add do |transport, value|
        interface_class = PuppetX::DellPowerconnect::Model::Interface::Base
        channel_name = "port-channel %s" % scope_name
        tagged, _untagged = interface_class.show_vlans(transport, channel_name)
        interface_class.update_tagged_vlans(transport, tagged, channel_name, value)
      end
      remove { |*_| }
    end

    ifprop(base, :untagged_general_vlans) do
      match /^\s*switchport general pvid\s+(\d+)$/
      after :switchport_mode
      add do |transport, value|
        interface_class = PuppetX::DellPowerconnect::Model::Interface::Base
        channel_name = "port-channel %s" % scope_name
        _tagged, untagged = interface_class.show_vlans(transport, channel_name)
        interface_class.update_untagged_vlans(transport, untagged, channel_name, value)
        interface_class.update_traffic_allowed_vlans(transport, channel_name, value)
      end
      remove { |*_|}
    end

    ifprop(base, :remove_general_vlans) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport general allowed vlan remove #{value}")
      end
      remove { |*_|}
    end

  end
end
