Puppet::Type.newtype(:powerconnect_portchannel) do
  @doc = "This represents a portchannel configuration on a router or switch."

  apply_to_device
  
  newparam(:name) do
    desc "port channel to be configured"
    isnamevar
    newvalues(/^\d+$/)
    validate do |value|
      if value.to_i < 1 or value.to_i > 128
        raise ArgumentError, "Port channel value can only be in the range of 1 - 128"
      end
      self.class.value_collection.validate(value)
    end
  end

  newproperty(:allowvlans) do
    desc "list of vlans to be tagged to the port channel"
    newvalues(/^(\d+(-\d+)?,)*\d+(-\d+)?$/)    
  end
  
  newproperty(:removevlans) do
    desc "list of vlans to be untagged from the port channel"
    newvalues(/^(\d+(-\d+)?,)*\d+(-\d+)?$/)
  end
    
end
