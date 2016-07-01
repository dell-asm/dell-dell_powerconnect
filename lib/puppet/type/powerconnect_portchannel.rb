Puppet::Type.newtype(:powerconnect_portchannel) do
  @doc = "Configures the port-channel in a PowerConnect switch"

  newparam(:name) do
    desc "Port-channel number"
    isnamevar
    newvalues(/^\d+$/)
    validate do |value|
      if value.to_i < 1 or value.to_i > 128
        raise ArgumentError, "Port channel value can only be in the range of 1 - 128"
      end
      self.class.value_collection.validate(value)
    end
  end

  newproperty(:tagged_general_vlans, :array_matching => :all) do
    desc "VLANs to be tagged on to the port-channel"
  end

  newproperty(:untagged_general_vlans, :array_matching => :all) do
    desc "VLANs to be tagged on general mode to the port-channel"
  end

  newproperty(:switchport_mode) do
    desc "Configure the VLAN membership mode of an interface. Valid values are access, trunk, or general."
    newvalues(:access, :general, :trunk)
  end

  newproperty(:shutdown) do
    desc "Disable the interface. Default value is 'false'"
    defaultto(false)
    newvalues(true, false)
  end

end
