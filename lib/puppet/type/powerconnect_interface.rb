Puppet::Type.newtype(:powerconnect_interface) do
  @doc = "This represents a switch interface."

  apply_to_device

  newparam(:name) do
    desc "The interface's name."
    newvalues(/^\w+[Gg]igabitethernet\S+$/, /Gi\S+$/,  /[Tt]engigabitethernet\S+$/, /[Tt]e\S+$/)
    isnamevar
  end

  newproperty(:description) do
    desc "The description of the interface."
    isrequired
    newvalues(/("([^"]*)")|(\A[^\n\s]\S+$)/)
  end

  newproperty(:mode) do
    desc "Set the mode of the interface."
    defaultto(:absent)
    newvalues(:absent, :access, :general, :private, :trunk)
  end

  newproperty(:add_vlans_general_mode) do
    desc "List of allowed VLANs in general mode"
    defaultto(:absent)
    newvalues(:absent, /^(\d+(-\d+)?,)*\d+(-\d+)?$/)

    validate do |value|
      if resource.value(:mode) != :general and value != :absent
        raise ArgumentError, "May only be set if mode is general"
      end

      self.class.value_collection.validate(value)
    end
  end

  newproperty(:remove_vlans_general_mode) do
    desc "List of VLANs to be removed in general mode"
    defaultto(:absent)
    newvalues(:absent, /^(\d+(-\d+)?,)*\d+(-\d+)?$/)

    validate do |value|
      self.class.value_collection.validate(value)
    end
  end

  newproperty(:add_vlans_trunk_mode) do
    desc "List of allowed VLANs in trunk mode"
    defaultto(:absent)
    newvalues(:absent, /^(\d+(-\d+)?,)*\d+(-\d+)?$/)

    validate do |value|
      if resource.value(:mode) != :trunk and value != :absent
        raise ArgumentError, "May only be set if mode is trunk"
      end

      self.class.value_collection.validate(value)
    end
  end

  newproperty(:remove_vlans_trunk_mode) do
    desc "List of VLANs to be removed in trunk mode"
    defaultto(:absent)
    newvalues(:absent, /^(\d+(-\d+)?,)*\d+(-\d+)?$/)

    validate do |value|
      self.class.value_collection.validate(value)
    end
  end

  newproperty(:mtu) do
    desc "Set mtu of the interface. mtu vlaue must be between 1518-9216."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)

    validate do |value|
      return if value == :absent
      raise ArgumentError, "'mtu' vlaue must be between 1518-9216" unless value.to_i >= 1518 && value.to_i <= 9216
    end
  end

  newproperty(:shutdown) do
    desc "Enable or disable  the interface."
    defaultto(false)
    newvalues(true,false)
  end

  newproperty(:add_interface_to_portchannel) do
    desc "Add the interface to the portcahnnel specified. Value of the port-channel number should be in between 1-128."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      return unless value.to_s.match(/^\d+$/)
      raise ArgumentError, "Port-channel' vlaue must be between 1-128." unless value.to_i >= 1 && value.to_i <= 128
    end
  end

  newproperty(:remove_interface_from_portchannel) do
    desc "Remove the interface from the portcahnnel specified. Specify 'true' to remove this interface from portchannel"
    defaultto(false)
    newvalues(false,true)
  end
end

