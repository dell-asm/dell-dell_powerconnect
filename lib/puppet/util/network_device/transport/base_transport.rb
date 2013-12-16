require 'puppet/util/network_device'
require 'puppet/util/network_device/transport'

class Puppet::Util::NetworkDevice::Transport::Base_transport
  attr_accessor :user, :password, :host, :port, :default_prompt, :timeout, :cache

  def initialize
    @timeout = 10
    @cache = {}
  end

  def send(cmd, noop)
  end

  def expect(prompt)
  end

  def command(cmd, options = {})
    Puppet.debug "cmd is : #{cmd}"
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
