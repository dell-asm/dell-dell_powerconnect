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
    #newvalues(/^\S+$/)
  end
end
