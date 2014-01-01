Puppet::Type.newtype(:powerconnect_config) do
  @doc = "Apply configuration on powerconnect router or switch."

  apply_to_device

  newparam(:name) do
    isnamevar
  end

  newparam(:url) do     
    validate do |url|
      raise ArgumentError, "Urlmust be a in format of tftp://${deviceRepoServerIPAddress}/${fileLocation} " unless url.is_a? String
      raise ArgumentError, "Unsupporte file format, supported file format is scr" unless url.end_with?('.scr')
      raise ArgumentError, "Tftp is the only supported file transfer protocol" unless url.start_with?('tftp://')
    end
  end  

  newparam(:config_type) do
    desc "Whether the provided configuration is startup configuration or running configuration"    
    newvalues(/((\bstartup\b)|(\brunning\b))/)
  end
  
  newparam(:force) do
   desc "Whether the provided configuration has to be applied in force"
   newvalues(:true, :false)
   defaultto :false
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
      Puppet.debug "currentvalue = #{currentvalue} newvalue = #{newvalue}"
      "executed successfully"
    end

    def retrieve

    end

    def sync
   
      event = :executed_command
      provider.run(self.resource[:url], self.resource[:config_type], self.resource[:force]) 
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end  
end
