require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_vlan).provide :dell_powerconnect, :parent => Puppet::Provider::DellPowerconnect do

  desc "Dell PowerConnect switch provider for VLAN configuration."
  @doc = "Dell PowerConnect switch provider for VLAN configuration."

  mk_resource_methods

  def self.get_current(name)
    transport.switch.vlan(name).params_to_hash
  end

  def flush
    transport.switch.vlan(name).update(former_properties, properties)
    super
  end
end
