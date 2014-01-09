Puppet::Type.newtype(:powerconnect_portchannel) do
  @doc = "Configures the port-channel in a PowerConnect switch"

  apply_to_device
  
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

  newproperty(:allowvlans) do
    desc "VLANs to be tagged on to the port-channel"
    newvalues(/^(\d+(-\d+)?,)*\d+(-\d+)?$/)    
  end
  
  newproperty(:removevlans) do
    desc "VLANs to be untagged from the port-channel"
    newvalues(/^(\d+(-\d+)?,)*\d+(-\d+)?$/)
  end
    
end
