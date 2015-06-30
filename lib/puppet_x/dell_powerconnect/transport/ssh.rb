#Module for establishing SSH connectivity to PowerConnect switch
require 'puppet/util/network_device/transport/ssh'

class PuppetX::DellPowerconnect::Transport::Ssh < Puppet::Util::NetworkDevice::Transport::Ssh

  def sendwithoutnewline(line, noop = false)
    #Puppet.debug "SSH data sent: #{line}" if Puppet[:debug]
    @channel.send_data(line) unless noop
  end
end
