require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_portchannel).provide :dell_powerconnect, :parent => Puppet::Provider::Dell_powerconnect do
  desc "PowerConnect switch port channel configuration"
  mk_resource_methods
  def initialize(device, *args)
    super
  end

  def self.lookup(device, name)
    device.switch.portchannel(name).params_to_hash
  end

  def flush
    device.switch.portchannel(name).update(former_properties, properties)
    super
  end
end
