Puppet::Type.newtype(:powerconnect_vlan) do
  @doc = "Configures VLANs on a PowerConnect switch"

  ensurable

  newparam(:name) do
    @doc = "VLAN Id"
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
