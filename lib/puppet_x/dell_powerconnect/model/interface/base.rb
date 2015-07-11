require 'puppet_x/dell_powerconnect/model/interface'

module PuppetX::DellPowerconnect::Model::Interface::Base
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
    configureinterface(base, :portfast, "spanning-tree") do
      match /switchport mode ([\w-]+)/
      add do |transport, value|
        if value == :true
          transport.command("#{spanning-tree} portfast")
        else
          transport.command("no #{spanning-tree} portfast")
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :switchport_mode, "switchport mode") do
      match /switchport mode ([\w-]+)/
      add do |transport, value|
        transport.command("switchport mode #{value}")
      end
      remove { |*_| }
    end
    configureinterface(base, :access_vlan) do
      match /switchport access vlan/
      add do |transport, value|
        transport.command("switchport access vlan  #{value}")
      end
      remove { |*_| }
    end
    configureinterface(base, :remove_access_vlan) do
      match /switchport access vlan/
      add do |transport, value|
        if value == :true
          transport.command("no switchport access vlan")
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :tagged_general_vlans) do
      match /^\s*switchport general allowed vlan add\s+(.*)\s*tagged$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport general allowed vlan add #{value} tagged") do |out|
          out.each_line do |line|
            if line.match(/ERROR:/)
              Puppet.warning "Could not add general tagged VLAN #{value}: #{line}"
            end
          end
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :untagged_general_vlans) do
      match /^\s*switchport general allowed vlan add\s+(.*)\s*(?<!tagged)$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport general pvid #{value}")
        transport.command("switchport general allowed vlan add #{value}") do |out|
          out.each_line do |line|
            if line.match(/ERROR:/)
              Puppet.warning "Could not add general untagged VLAN #{value}: #{line}"
            end
          end
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :remove_general_vlans) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport general allowed vlan remove #{value}")
      end
      remove { |*_| }
    end
    configureinterface(base, :trunk_vlans) do
      match /^\s*switchport trunk allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport trunk allowed vlan add #{value}") do |out|
          out.each_line do |line|
            if line.match(/ERROR:/)
              Puppet.warning "Could not add trunk tagged VLAN #{value}: #{line}"
              #raise "#{line}"
            end
          end
        end
      end
      remove { |*_| }
    end
    configureinterface(base, :remove_trunk_vlans) do
      match /^\s*switchport trunk allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
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
      match /shutdown/
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
