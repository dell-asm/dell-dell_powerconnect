require 'puppet'
require 'puppet/util'
require 'puppet/util/network_device/base_powerconnect'
require 'puppet/util/network_device/dell_powerconnect/facts'
require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/switch'

# Models the Dell PowerConnect switch resource. Initializes
# the switch connectivity and loads the facts related to it.
class Puppet::Util::NetworkDevice::Dell_powerconnect::Device < Puppet::Util::NetworkDevice::Base_powerconnect

  attr_accessor :enable_password, :switch

  def initialize(url, options = {})
    super(url)
    @enable_password = options[:enable_password] || parse_enable(@url.query)
    @initialized = false
    transport.default_prompt = /[#>]\s?\z/n
  end

  def parse_enable(query)
    return $1 if query =~ /enable=(.*)/
  end

  def connect_transport
    transport.connect
    login
    enable
    transport.command("terminal length 0", :noop => false)
  end

  def login
    return if transport.handles_login?
    if @url.user != ''
      transport.command(@url.user, {:prompt => /^Password:/, :noop => false})
    else
      transport.expect(/^Password:/)
    end
    transport.command(@url.password, :noop => false)
  end

  def enable
    raise "Can't issue \"enable\" to enter privileged, no enable password set" unless enable_password
    transport.command("enable", {:noop => false}) do |out|
      out.each_line do |line|
       if line.start_with?("Password:")
         transport.send(enable_password+"\r")
	 return
       end
      end
    end
  end

  def init
    # TODO: Stop being an Idiot ...
    unless @initialized
      connect_transport
      init_facts
      init_switch
      @initialized = true
    end
    return self
  end

  def init_switch
    @switch ||= Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch.new(transport, @facts.facts_to_hash)
    @switch.retrieve
  end

  def init_facts
    @facts ||= Puppet::Util::NetworkDevice::Dell_powerconnect::Facts.new(transport)
    @facts.retrieve
  end

  def facts
    # This is here till we can fork Puppet
    init
    @facts.facts_to_hash
  end
end
