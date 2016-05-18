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
        transport.command("no #{base_command} #{old_value}")
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
      remove { |*_|}
    end

    configureinterface(base, :switchport_mode, "switchport mode") do
      match /switchport mode ([\w-]+)/
      add do |transport, value|
        transport.command("switchport mode #{value}")
      end
      remove { |*_|}
    end

    configureinterface(base, :access_vlan) do
      match /switchport access vlan/
      add do |transport, value|
        transport.command("switchport access vlan  #{value}")
      end
      remove { |*_|}
    end

    configureinterface(base, :remove_access_vlan) do
      match /switchport access vlan/
      add do |transport, value|
        if value == :true
          transport.command("no switchport access vlan")
        end
      end
      remove { |*_|}
    end

    configureinterface(base, :tagged_general_vlans) do
      match /^\s*switchport general allowed vlan add\s+(.*)\s*tagged$/
      after :switchport_mode
      add do |transport, value|
        interface_info = PuppetX::DellPowerconnect::Model::Interface::Base.interface_type(scope_name)
        tagged, untagged = PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport, interface_info)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_tagged_vlans(transport, [tagged, untagged], interface_info, value)
      end
      remove { |*_|}
    end

    configureinterface(base, :untagged_general_vlans) do
      match /^\s*switchport general pvid\s+(\d+)$/
      after :switchport_mode
      add do |transport, value|
        interface_info = PuppetX::DellPowerconnect::Model::Interface::Base.interface_type(scope_name)
        tagged, untagged = PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport, interface_info)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_untagged_vlans(transport, [tagged, untagged], interface_info, value)
      end
      remove { |*_|}
    end

    configureinterface(base, :remove_general_vlans) do
      match /^\s*switchport general allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport general allowed vlan remove #{value}")
      end
      remove { |*_|}
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
      remove { |*_|}
    end

    configureinterface(base, :remove_trunk_vlans) do
      match /^\s*switchport trunk allowed vlan\s+(.*?)\s*$/
      after :switchport_mode
      add do |transport, value|
        transport.command("switchport trunk allowed vlan remove #{value}")
      end
      remove { |*_|}
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
      remove { |*_|}
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
      remove { |*_|}
    end
  end

  def self.interface_type(interface_id)
    return interface_id.split("/")
  end

  def self.show_vlans(transport, interface_val)
    get_vlan_info = transport.command("show running-config interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
    get_vlan_info.match /^switchport general pvid (\d+)$/
    if $1.nil? || $1.empty?
      untagged = []
    else
      untagged = [$1.to_i]
    end
    meta_data = get_vlan_info.match /^switchport general allowed vlan add (.+?) tagged$/
    tagged = []
    str = meta_data.nil? ? "" : meta_data[1]
    str_arr = str.split(",")
    str_arr.each do |num_str|
      num = num_str.to_i
      if num_str == num.to_s
        tagged << num
      else
        nums = num_str.split("-").map(&:to_i)
        nums[0].upto(nums[1]).each do |range_num|
          tagged << range_num
        end
      end
    end
    return [tagged, untagged]
  end

  def self.update_tagged_vlans(transport, existing_vlans, interface_val, value)
    tagged_vlans = existing_vlans[0]
    value = value.split(",").map(&:to_i)
    current_vlans = tagged_vlans
    transport.command("config")

    vlans_to_remove = current_vlans - value
    vlans_to_remove.each do |vlan|
      Puppet.debug("Removing opposite vlans of #{vlan}")
      transport.command("interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan remove #{vlan}")
    end

    vlans_to_add = value - current_vlans
    vlans_to_add.each do |val|
      Puppet.debug("Adding vlans #{val}")
      transport.command("interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan add #{val} tagged")
    end
    transport.command("show running-config interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
  end

  def self.update_untagged_vlans(transport, existing_vlans, interface_val, value)
    untagged_vlans = existing_vlans[1]
    raise(ArgumentError, "Too many untagged vlans on port %s: %s" % [interface_val.join("/"), untagged_vlans.join(", ")]) if untagged_vlans.size > 1

    value = value.split(",").map(&:to_i)
    raise(ArgumentError, "Too many untagged vlans requested: %s" % value) if untagged_vlans.size > 1

    vlans_to_add = value - untagged_vlans
    return if vlans_to_add.empty?
    raise(ArgumentError, "Invalid number of vlans to add: %s" % untagged_vlans.join(", ")) if vlans_to_add.size > 1

    untagged_vlan = vlans_to_add.first
    Puppet.debug("Adding vlans #{untagged_vlan}")
    transport.command("interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
    transport.command("switchport mode general")
    transport.command("switchport general allowed vlan add #{untagged_vlan}")
    transport.command("switchport general pvid #{untagged_vlan}")

    transport.command("show running-config interface #{interface_val[0]}/#{interface_val[1]}/#{interface_val[2]}")
  end
end
