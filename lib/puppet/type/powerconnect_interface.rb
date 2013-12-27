Puppet::Type.newtype(:powerconnect_interface) do
  @doc = "Configure a switch interface."

  apply_to_device

  newparam(:name) do
    desc "The interface's name. Valid interface name should start with Gigabitethernet or Gi or Tengigabitethernet or Te followed by unit/slot/port."
    isnamevar
    validate do |value|
      unless value =~ /^\A[Gg]igabitethernet\s*\S+$/ or value =~ /Gi\s*\S+$/ or value =~ /[Tt]engigabitethernet\s*\S+$/  or value =~ /[Tt]e\s*\S+$/
        raise ArgumentError, "%s is not a valid interface name. Valid interface name should start with 'Gigabitethernet or Gi or Tengigabitethernet or Te' followed by unit/slot/port." % value
      end
    end

  end

  newproperty(:description) do
    desc "The description of the port attached to this interface."
    newvalues(/("([^"]*)")|(\A[^\n\s]\S+$)/)
  end

  newproperty(:mode) do
    desc "Configure the VLAN membership mode of an interface. Valid values are access, trunk, or general."
    newvalues(:access, :general, :trunk)
  end

  newproperty(:add_vlans_general_mode) do
    desc "Add VLANs to a general port. Specify the list of valid VLAN IDs to be added. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      unless value =~ /^(\d+(-\d+)?,)*\d+(-\d+)?$/
        raise ArgumentError, "%s is not a valid input for add_vlans_general_mode. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs." % value
      end
    end
  end

  newproperty(:remove_vlans_general_mode) do
    desc "Remove VLANs from a general port. Specify the list of valid VLAN IDs to be removed. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      unless value =~ /^(\d+(-\d+)?,)*\d+(-\d+)?$/
        raise ArgumentError, "%s is not a valid input for remove_vlans_general_mode. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs." % value
      end
    end
  end

  newproperty(:add_vlans_trunk_mode) do
    desc "Add VLANs to a trunk port. Specify the list of valid VLAN IDs to be added. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      unless value =~ /^(\d+(-\d+)?,)*\d+(-\d+)?$/
        raise ArgumentError, "%s is not a valid input for add_vlans_trunk_mode. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs." % value
      end
    end
  end

  newproperty(:remove_vlans_trunk_mode) do
    desc "Remove VLANs from a trunk port. Specify the list of valid VLAN IDs to be removed. Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs."
    validate do |value|
      unless value =~ /^(\d+(-\d+)?,)*\d+(-\d+)?$/
        raise ArgumentError, "%s is not a valid input for remove_vlans_trunk_mode.  Separate nonconsecutive VLAN IDs with a comma and no spaces. Use a hyphen to designate a range of IDs." % value
      end
    end
  end

  newproperty(:mtu) do
    desc "Set mtu of the interface. The 'mtu' vlaue must be between 1518 and 9216."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid mtu value is entered. The 'mtu' vlaue must be between 1518 and 9216." unless value.to_i >= 1518 && value.to_i <= 9216
    end
  end

  newproperty(:shutdown) do
    desc "Enable or disable the interface. Specify 'true' to disable the interface."
    defaultto(false)
    newvalues(true,false)
  end

  newproperty(:add_interface_to_portchannel) do
    desc "Associate the interface with a portchannel. The 'Port-channel' vlaue must be between 1 and 128."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      return unless value.to_s.match(/^\d+$/)
      raise ArgumentError, "An invalid portchannel value is entered. The 'Port-channel' vlaue must be between 1 and 128." unless value.to_i >= 1 && value.to_i <= 128
    end
  end

  newproperty(:remove_interface_from_portchannel) do
    desc "Remove the interface from the portchannel. Specify 'true' to remove this interface from the portchannel"
    defaultto(false)
    newvalues(false,true)
  end
end
