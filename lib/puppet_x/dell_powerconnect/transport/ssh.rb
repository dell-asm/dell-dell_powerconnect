#Module for establishing SSH connectivity to PowerConnect switch
require 'puppet/util/network_device/transport/ssh'

class PuppetX::DellPowerconnect::Transport::Ssh < Puppet::Util::NetworkDevice::Transport::Ssh
  def initialize(verbose=true)
    @cache = {}
    super(verbose)
  end

  def sendwithoutnewline(line, noop = false)
    #Puppet.debug "SSH data sent: #{line}" if Puppet[:debug]
    @channel.send_data(line) unless noop
  end

  def command(cmd, options = {})
    return @cache[cmd] if options[:cache] && @cache[cmd]
    send(cmd)
    out = expect(options[:prompt] || default_prompt) do |output|
      yield output if block_given?
    end
    @cache[cmd] = out if options[:cache]
    out
  end
end
