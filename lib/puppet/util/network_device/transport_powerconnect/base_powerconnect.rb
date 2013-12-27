#Parent class for all supported transport protocols.
require 'puppet/util/network_device'
require 'puppet/util/network_device/transport_powerconnect'

class Puppet::Util::NetworkDevice::Transport_powerconnect::Base_powerconnect
  attr_accessor :user, :password, :host, :port, :default_prompt, :timeout, :cache

  def initialize
    @timeout = 10
    @cache = {}
  end

  def send(cmd, noop)
    Puppet.debug "Override Me: cmd = #{cmd} noop = #{noop}"
  end

  def expect(prompt)
    Puppet.debug "Override Me: prompt = #{prompt}"
  end 

  def command(cmd, options = {})
    noop = options[:noop].nil? ? Puppet[:noop] : options[:noop]
    if options[:cache]
      return @cache[cmd] if @cache[cmd]
      send(cmd, noop)
      unless noop
        @cache[cmd] = expect(options[:prompt] || default_prompt)
      end
    else
      send(cmd, noop)
      unless noop
        expect(options[:prompt] || default_prompt) do |output|
          yield output if block_given?
        end
      end
    end
  end
end
