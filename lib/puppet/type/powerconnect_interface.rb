Puppet::Type.newtype(:powerconnect_interface) do
  @doc = "Configures PowerConnect switch interface"

  newparam(:name) do
    desc "Name of the interface. Valid values start with Gigabitethernet or Gi or Tengigabitethernet or Te followed by unit/slot/port."
    isnamevar
    validate do |value|
      unless value =~ /^\A[Gg]igabitethernet\s*\S+$/ or value =~ /Gi\s*\S+$/ or value =~ /[Tt]engigabitethernet\s*\S+$/  or value =~ /[Tt]e\s*\S+$/
        raise ArgumentError, "%s is not a valid interface name. Valid interface name should start with 'Gigabitethernet or Gi or Tengigabitethernet or Te' followed by unit/slot/port." % value
      end
    end

  end

  newproperty(:description) do
    desc "Description of the port attached to this interface."
    newvalues(/("([^"]*)")|(\A[^\n\s]\S+$)/)
  end

  newproperty(:switchport_mode) do
    desc "Configure the VLAN membership mode of an interface. Valid values are access, trunk, or general."
    newvalues(:access, :general, :trunk)
  end

  newproperty(:portfast) do
    desc "Whether to enable or disable spanning-tree portfast"
    newvalues(:true, :false)
  end

  newproperty(:access_vlan) do
      desc "Configures the VLAN ID when the interface is in access mode."
      defaultto(:absent)
      newvalues(:absent, /^\d+$/)
      validate do |value|
        return if value == :absent || value.empty?
        raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
        value.split(',').each do |vlan_value|
          raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
          vlan_value.split('-').each do |vlan|
            all_valid_characters = vlan =~ /^[0-9]+$/
            raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
          end
        end
      end
    end
  
    newproperty(:remove_access_vlan) do
      desc "Remove the VLAN configured in access mode."
      defaultto(false)
      newvalues(false,true)
      validate do |value|
        return if value == :absent || value.empty?
        raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
        value.split(',').each do |vlan_value|
          raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
          vlan_value.split('-').each do |vlan|
            all_valid_characters = vlan =~ /^[0-9]+$/
            raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
          end
        end
      end
    end
    
  newproperty(:tagged_general_vlans) do
    desc "VLANs to add to a general port. Specify non consecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of VLAN IDs."
    validate do |value|
      return if value == :absent || value.empty?
      raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
      value.split(',').each do |vlan_value|
        raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
        vlan_value.split('-').each do |vlan|
          all_valid_characters = vlan =~ /^[0-9]+$/
          raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
        end
      end
    end
  end

   newproperty(:untagged_general_vlans) do
    desc "Untagged VLANs to add to a general port. Specify non consecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of VLAN IDs."
    validate do |value|
      return if value == :absent || value.empty?
      raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
      value.split(',').each do |vlan_value|
        raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
        vlan_value.split('-').each do |vlan|
          all_valid_characters = vlan =~ /^[0-9]+$/
          raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
        end
      end
    end
  end

  newproperty(:remove_general_vlans) do
    desc "VLANs to remove from a general port. Specify non consecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      return if value == :absent || value.empty?
      raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
      value.split(',').each do |vlan_value|
        raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
        vlan_value.split('-').each do |vlan|
          all_valid_characters = vlan =~ /^[0-9]+$/
          raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
        end
      end
    end
  end

  newproperty(:trunk_vlans) do
    desc "VLANs to add to a trunk port. Specify non consecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      return if value == :absent || value.empty?
      raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
      value.split(',').each do |vlan_value|
        raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
        vlan_value.split('-').each do |vlan|
          all_valid_characters = vlan =~ /^[0-9]+$/
          raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
        end
      end
    end
  end

  newproperty(:remove_trunk_vlans) do
    desc "Remove VLANs from a trunk port. Specify non consecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      return if value == :absent || value.empty?
      raise ArgumentError, "Invalid vlan list: #{value}" if value.include?(',') && !(value.split(',').size > 0)
      value.split(',').each do |vlan_value|
        raise ArgumentError, "Invalid range definition: #{value}" if value.include?('-') && value.split('-').size != 2
        vlan_value.split('-').each do |vlan|
          all_valid_characters = vlan =~ /^[0-9]+$/
          raise ArgumentError, "An invalid VLAN ID #{vlan_value} is entered.All VLAN values must be between 1 and 4094." unless all_valid_characters && vlan.to_i >= 1 && vlan.to_i <= 4094
        end
      end
    end
  end

  newproperty(:mtu) do
    desc "MTU of the interface. Value must be between 1518 and 9216."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid mtu value is entered. The 'mtu' vlaue must be between 1518 and 9216." unless value.to_i >= 1518 && value.to_i <= 9216
    end
  end

  newproperty(:shutdown) do
    desc "Disable the interface. Default value is 'false'"
    defaultto(false)
    newvalues(true,false)
  end

  newproperty(:add_interface_to_portchannel) do
    desc "Associate the interface with a port-channel. The 'Port-channel' value must be between 1 and 128."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      return unless value.to_s.match(/^\d+$/)
      raise ArgumentError, "An invalid portchannel value is entered. The 'Port-channel' vlaue must be between 1 and 128." unless value.to_i >= 1 && value.to_i <= 128
    end
  end

  newproperty(:remove_interface_from_portchannel) do
    desc "Remove the interface from the port-channel. Default value is 'false'"
    defaultto(false)
    newvalues(false,true)
  end
end
