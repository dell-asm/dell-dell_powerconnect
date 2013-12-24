Puppet::Type.newtype(:powerconnect_config) do
  @doc = "Apply configuration on powerconnect router or switch."

  apply_to_device

  newparam(:name) do
    isnamevar
  end

  newparam(:url) do     
    validate do |url|
      raise ArgumentError, "Urlmust be a in format of tftp://${deviceRepoServerIPAddress}/${fileLocation} " unless url.is_a? String
    end
  end  

  newparam(:config_type) do
    desc "Whether the provided configuration is startup configuration or running configuration"    
  end

  newproperty(:returns, :event => :executed_command) do |property|
    munge do |value|
      value.to_s
    end

    def event_name
      :executed_command
    end

    defaultto "#"

    def change_to_s(currentvalue, newvalue)
      "executed successfully"
    end

    def retrieve

    end

    def sync
   
      event = :executed_command
      out = provider.run(self.resource[:url], self.resource[:config_type]) 
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end  
end
