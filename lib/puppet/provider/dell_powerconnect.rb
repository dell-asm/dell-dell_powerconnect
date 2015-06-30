require 'puppet/provider/network_device'

# This is the base Class of all prefetched Dell PowerConnect device providers
class Puppet::Provider::DellPowerconnect < Puppet::Provider::NetworkDevice
  attr_accessor :transport

  def initialize(*args)
    super(nil, *args)
    @transport = @property_hash.delete(:transport)
    @properties.delete(:transport)
  end

  def self.transport
    @transport ||= PuppetX::DellPowerconnect::Transport.new(Puppet[:certname])
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      result = get_current(name)
      #We want to pass the transport through so we don't keep initializing new ssh connections for every single resource
      result[:transport] = transport
      transport
      if result
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end
end