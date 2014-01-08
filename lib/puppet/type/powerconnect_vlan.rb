Puppet::Type.newtype(:powerconnect_vlan) do
  @doc = "This represents a VLAN configuration on a Dell PowerConnect switch."

  apply_to_device

  ensurable

  newparam(:name) do
    @doc = "The VLAN Id"
    isnamevar
    newvalues(/^\d+$/)
  end

  newproperty(:vlan_name) do
    @doc = "Name of the VLAN (optional)"
    validate do |value|
      raise ArgumentError, "An invalid name is entered for the VLAN ID. The name cannot exceed 32 characters." unless value.length <= 32
    end
  end
end
