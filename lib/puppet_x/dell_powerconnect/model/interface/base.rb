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
        interface_type=[]
        #scope_name will have respective consisting interface_type, module and port value for instance "Te1/0/29"
        scope_name.split("/").each do |val|
          interface_type<<val
        end
        tagged,untagged=PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport,interface_type)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_vlans(transport,[tagged,untagged],interface_type,value,true)
      end
      remove { |*_| }
    end

    configureinterface(base, :untagged_general_vlans) do
      match /^\s*switchport general allowed vlan add\s+(.*)\s*(?<!tagged)$/
      after :switchport_mode
      add do |transport, value|
        interface_type=[]
        scope_name.split("/").each do  |val|
          interface_type<<val
        end
        tagged,untagged=PuppetX::DellPowerconnect::Model::Interface::Base.show_vlans(transport,interface_type)
        PuppetX::DellPowerconnect::Model::Interface::Base.update_vlans(transport,[tagged,untagged],interface_type,value,false)
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
  # returns the all tagged and untagged vlans in an array
  def self.show_vlans(transport,interface_type)
    get_vlan_info=transport.command("show running-config interface #{interface_type[0]}/#{interface_type[1]}/#{interface_type[2]}")
    get_vlan_info.match /^switchport general pvid (\d+)$/
    untagged=[$1.to_i]
    meta_data=get_vlan_info.match /^switchport general allowed vlan add (.+?) tagged$/
    tagged=[]
    str=meta_data.nil? ? "" : meta_data[1]
    str_arr2=str.split(",")
    str_arr2.each do |num_str|
      num=Integer(num_str)
      if num_str == num.to_s
        tagged << num
      else
        nums=num_str.split("-").map(&:to_i)
        nums[0].upto(nums[1]).each do |range_num|
          tagged << range_num
        end
      end
    end
    return [tagged,untagged]
  end
  #removes only extra tagged unnecessary vlans with out removing existing tagged one(s)
  def self.update_vlans(transport,existing_vlans,interface_type,value,tagged)
    vlan_type = tagged ? "tagged" : "untagged"
    opposite_vlan_type = tagged ? "untagged" : "tagged"
    tagged_vlans=existing_vlans[0]
    untagged_vlans=existing_vlans[1]
    if value.include? ","
      curr_tagged_vlans=[]
      value.split(",").each do |val|
        curr_tagged_vlans << val.to_i
      end
      value=curr_tagged_vlans
    else
      value=[value.to_i]
    end
    if tagged
      current_vlans=tagged_vlans
      opposite_vlans_to_remove=current_vlans - value
    else
      current_vlans=untagged_vlans
      opposite_vlans_to_remove=current_vlans - value
    end
    # some times switch will exit automaticlaly while prefetching data to overcome that situation we were configuring
    transport.command("config")
    if !opposite_vlans_to_remove.empty?
      opposite_vlans_to_remove.each do |vlan|
        Puppet.debug("Removing opposite vlans of #{vlan}")
        transport.command("interface #{interface_type[0]}/#{interface_type[1]}/#{interface_type[2]}")
        transport.command("switchport mode general")
        transport.command("switchport general allowed vlan remove #{vlan}")
      end
    else
      transport.command("show running-config interface #{interface_type[0]}/#{interface_type[1]}/#{interface_type[2]}")
    end
    transport.command("show running-config interface #{interface_type[0]}/#{interface_type[1]}/#{interface_type[2]}")
  end
end