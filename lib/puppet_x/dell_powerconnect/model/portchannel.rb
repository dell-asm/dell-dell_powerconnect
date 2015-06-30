#Module for configuring port-channels for PowerConnect switch
require 'puppet/util/network_device/ipcalc'
require 'puppet_x/dell_powerconnect/model/base'
require 'puppet_x/dell_powerconnect/model/scoped_value'

class PuppetX::DellPowerconnect::Model::Portchannel < PuppetX::DellPowerconnect::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def mod_path_base
    return 'puppet_x/dell_powerconnect/model/portchannel'
  end

  def mod_const_base
    return PuppetX::DellPowerconnect::Model::Portchannel
  end

  def param_class
    return PuppetX::DellPowerconnect::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end

  def before_update
    super
    transport.command("interface port-channel #{name}", :prompt => /\(config-if-Po\d+\)#\s?\z/n)
  end

  def after_update
    transport.command("exit")
    super
  end

end
