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
        transport.command("no #{base_command} #{old_value} ")
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
          transport.command("spanning-tree portfast")
        else
          transport.command("no spanning-tree portfast")
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
        scope_port_name = (scope_name.split("/").last).to_i
        tagged, untagged =PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport,scope_port_name)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_vlans(transport,[tagged,untagged],scope_port_name,value,true)
      end
      remove { |*_| }
    end

    configureinterface(base, :untagged_general_vlans) do
      match /^\s*switchport general allowed vlan add\s+(.*)\s*(?<!tagged)$/
      after :switchport_mode
      add do |transport, value|
        scope_port_name = (scope_name.split("/").last).to_i
        tagged, untagged = PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport,scope_port_name)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_vlans(transport,[tagged,untagged],scope_port_name,value,false)
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

  def self.show_vlans(transport,port_value)
    get_vlan_info = transport.command("show running-config interface tengigabitethernet 1/0/#{port_value}")
    get_vlan_info.match /^switchport general pvid (\d+)$/
    untagged=[$1.to_i]
    get_vlan_info.match /^switchport general allowed vlan add\s+((\d+.){1,})tagged$/
    tagged = []
    if(!$1.nil?)
      $1.split(',').each do |val|
        if val.match(/\s*(\d+)-(\d+)/)
          tagged += ($1.to_i..$2.to_i).to_a
        else
          tagged << val.to_i
        end
      end
    end
    return [tagged,untagged]
  end

  def self.update_vlans(transport,existing_vlans,port_value,value,tagged)
    vlan_type = tagged ? "tagged" : "untagged"
    opposite_vlan_type= tagged ? "untagged" : "tagged"
    tagged_vlans = existing_vlans[0]
    untagged_vlans = existing_vlans[1]
    if value.include? ","
      curr_tagged_vlans=[]
      value.split(",").each do |val|
        curr_tagged_vlans << val.to_i
      end
      value = curr_tagged_vlans
    else
      value = [value.to_i]
    end
    if tagged
      current_vlans = tagged_vlans
      opposite_vlans_to_remove = current_vlans - value
    else
      current_vlans = untagged_vlans
      opposite_vlans_to_remove = current_vlans - value
    end

    transport.command("config")

    if !opposite_vlans_to_remove.empty?
      opposite_vlans_to_remove.each do |vlan|
        Puppet.debug("Removing opposite vlans of #{vlan}")
        transport.command("interface  tengigabitethernet 1/0/#{port_value}")
        transport.command("switchport mode general")
        transport.command("switchport general allowed vlan remove #{vlan}")
      end
    else
      transport.command("show running-config interface tengigabitethernet 1/0/#{port_value}")
    end

    transport.command("show running-config interface tengigabitethernet 1/0/#{port_value}")
  end
end
