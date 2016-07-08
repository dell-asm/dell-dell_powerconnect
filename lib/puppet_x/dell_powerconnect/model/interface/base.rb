require 'puppet_x/dell_powerconnect/model/interface'

module PuppetX::DellPowerconnect::Model::Interface::Base

  def self.configureinterface(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\s+(\S+).*?)^!/m do
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
        base_class = PuppetX::DellPowerconnect::Model::Interface::Base
        tagged, _untagged = base_class.show_vlans(transport, scope_name)
        base_class.update_tagged_vlans(transport, tagged, scope_name, value)
      end
      remove { |*_|}
    end

    configureinterface(base, :untagged_general_vlans) do
      match /^\s*switchport general pvid\s+(\d+)$/
      after :switchport_mode
      add do |transport, value|
        base_class = PuppetX::DellPowerconnect::Model::Interface::Base
        tagged, untagged = base_class.show_vlans(transport, scope_name)
        base_class.update_untagged_vlans(transport, untagged, scope_name, value)
        base_class.update_traffic_allowed_vlans(transport, scope_name, value)
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

  def self.show_vlans(transport, interface_name)
    get_vlan_info =
      transport.command("show running-config interface %s" % interface_name)
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

  def self.update_tagged_vlans(transport, tagged_vlans, interface_name, requested_vlans)
    requested_vlans = requested_vlans.split(",").map(&:to_i)
    current_vlans = tagged_vlans
    transport.command("exit") # Bring us back to configure state

    vlans_to_remove = current_vlans - requested_vlans
    vlans_to_remove.each do |vlan|
      Puppet.debug("Removing opposite vlans of %s" % vlan)
      transport.command("interface %s" % interface_name)
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan remove %s" % vlan)
      transport.command("exit")
    end

    vlans_to_add = requested_vlans - current_vlans
    vlans_to_add.each do |vlan|
      Puppet.debug("Adding vlan %s" % vlan)
      transport.command("interface %s" % interface_name)
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan add %s tagged" % vlan)
      transport.command("exit") #exit from interface
    end
    transport.command("interface %s" % interface_name) # Revert back to original state
  end


  def self.update_untagged_vlans(transport, untagged_vlans, interface_name, requested_vlans)
    raise(ArgumentError, "Too many untagged vlans on port %s: %s" % [interface_name, untagged_vlans.join(", ")]) if untagged_vlans.size > 1

    requested_vlans = requested_vlans.split(",").map(&:to_i)
    raise(ArgumentError, "Too many untagged vlans requested: %s" % requested_vlans) if untagged_vlans.size > 1

    vlans_to_add = requested_vlans - untagged_vlans
    return if vlans_to_add.empty?
    raise(ArgumentError, "Invalid number of vlans to add: %s" % untagged_vlans.join(", ")) if vlans_to_add.size > 1

    untagged_vlan = vlans_to_add.first
    Puppet.debug("Adding vlans %s" % untagged_vlan)
    transport.command("exit") # bring us back to config state
    transport.command("interface %s" % interface_name)
    transport.command("switchport mode general")
    transport.command("switchport general pvid %s" % untagged_vlan)
    transport.command("exit") # bring us back to config state
    transport.command("interface %s" % interface_name) # Bring back to original state
  end

  def self.update_traffic_allowed_vlans(transport, interface_name, requested_vlans)
    get_vlan_info = transport.command("show running-config interface %s" % interface_name)
    meta_data = get_vlan_info.match /^switchport general allowed vlan add ([0-9,-]+)$/
    vlan_info = meta_data.nil? ? "" : meta_data[1]
    vlan_arr = vlan_info.split(",")
    vlan_allowed = []
    requested_vlans = requested_vlans.split(",").map(&:to_i)
    vlan_arr.each do |num_str|
      num = num_str.to_i
      if num_str == num.to_s
        vlan_allowed << num
      else
        nums = num_str.split("-").map(&:to_i)
        nums[0].upto(num[1]).each do |range_num|
          vlan_allowed << range_num
        end
      end
    end

    transport.command("exit") # bring us back to config state

    vlans_to_remove = vlan_allowed - requested_vlans
    vlans_to_remove.each do |vlan|
      Puppet.debug("Removing switchport allowed vlans %s" % vlan)
      transport.command("interface %s" % interface_name)
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan remove %s" % vlan)
      transport.command("exit")
    end

    vlans_to_add = requested_vlans - vlan_allowed
    vlans_to_add.each do |vlan|
      Puppet.debug("Adding switchport allowed vlan #{vlan}")
      transport.command("interface %s" % interface_name)
      transport.command("switchport mode general")
      transport.command("switchport general allowed vlan add %s" % vlan)
      transport.command("exit")
    end
    transport.command("interface %s" % interface_name)
  end
end
