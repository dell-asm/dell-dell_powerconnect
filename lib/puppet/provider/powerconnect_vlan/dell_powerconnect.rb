require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_vlan).provide :dell_powerconnect, :parent => Puppet::Provider::Dell_powerconnect do

  desc "Dell PowerConnect switch provider for VLAN configuration."

  mk_resource_methods
  def initialize(device, *args)
    super
  end

  def self.lookup(device, name)
    device.switch.vlan(name).params_to_hash
  end

  def flush
    device.switch.vlan(name).update(former_properties, properties)
    super
  end
end
