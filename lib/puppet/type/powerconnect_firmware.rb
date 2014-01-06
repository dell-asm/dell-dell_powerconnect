Puppet::Type.newtype(:powerconnect_firmware) do
  @doc = "Apply firmware upgrade on powerconnect router or switch."

  apply_to_device

  newparam(:name) do
    isnamevar
  end

  newparam(:imageurl) do
    validate do |imageurl|
      raise ArgumentError, "Url must be a in format of tftp://${TFTPServerIPAddress}/${imageLocation} " unless imageurl.is_a? String
    end
  end

  newparam(:forceupdate) do
    desc "Whether the provided firmware update has to be applied by force"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:saveconfig) do
    desc "Whether the switch configuration should be saved before rebooting the switch"
    newvalues(:true, :false)
    defaultto :true
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
      out = provider.run(self.resource[:imageurl], self.resource[:forceupdate], self.resource[:saveconfig])
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end
end
