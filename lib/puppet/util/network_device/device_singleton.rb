require 'puppet/util/network_device/dell_powerconnect/device'

class Puppet::Util::NetworkDevice::Device_singleton
  def self.lookup(url)
    @map ||= {}
    return @map[url] if @map[url]
    @map[url] = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new(url).init
    return @map[url]
  end

  def self.clear
    @map.clear
  end
end
