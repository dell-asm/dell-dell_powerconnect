require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_interface).provide :dell_powerconnect, :parent => Puppet::Provider::Dell_powerconnect do
  desc "Power Switch / Router Interface Provider for Device Configuration."
  mk_resource_methods

  def initialize(device, *args)
    super
  end

  def self.lookup(device, name)
    device.switch.interface(name).params_to_hash
  end

  def flush
    device.switch.interface(name).update(former_properties, properties)
    super
  end
end
