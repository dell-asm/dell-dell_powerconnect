#Module for configuring interfaces for PowerConnect Switch
require 'puppet/util/network_device/ipcalc'
require 'puppet_x/dell_powerconnect/model/base'
require 'puppet_x/dell_powerconnect/model/scoped_value'

class PuppetX::DellPowerconnect::Model::Interface < PuppetX::DellPowerconnect::Model::Base

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
    return 'puppet_x/dell_powerconnect/model/interface'
  end

  def mod_const_base
    return PuppetX::DellPowerconnect::Model::Interface
  end

  def param_class
    return PuppetX::DellPowerconnect::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end

  def before_update
    super
    transport.command("interface #{@name}") do |out|
      out.each_line do |line|
        Puppet.debug "line = #{line}"
        if line.include?("An invalid interface has been used for this function.")
          transport.command("exit")
          raise Puppet::Error, "The interface #{@name} does not exist. Please provide valid input and try the operation again."
        end
      end
    end
    transport.command("interface #{@name}", :prompt => /\(config-if-#{name}\)#\z/n)
  end

  def after_update
    transport.command("exit")
    super
  end

end
