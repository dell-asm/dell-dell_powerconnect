Puppet::Type.newtype(:powerconnect_firmware) do
  @doc = "Updates the PowerConnect switch firmware"

  apply_to_device

  newparam(:name) do
    isnamevar
  end

  newparam(:imageurl) do
    desc "Defines the TFTP URL where the firmware file is available"
    validate do |imageurl|
      raise ArgumentError, "Url must be a in format of tftp://${TFTPServerIPAddress}/${imageLocation} " unless imageurl.is_a? String
    end
  end

  newparam(:forceupdate) do
    desc "Overwrite any existing firmware"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:saveconfig) do
    desc "Save the switch running configuration before rebooting"
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
