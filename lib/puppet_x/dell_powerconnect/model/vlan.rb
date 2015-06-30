require 'puppet_x/dell_powerconnect/model/base'
require 'puppet_x/dell_powerconnect/model/scoped_value'

#Represents the implementation for VLAN puppet type.
#Provides the operations for managing the state of parameters.
class PuppetX::DellPowerconnect::Model::Vlan < PuppetX::DellPowerconnect::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  #This method is called to add/remove vlan and then save running config to startup config.
  def update(is = {}, should = {})
    return unless configuration_changed?(is, should, :keep_ensure => true)
    missing_commands = [is.keys, should.keys].flatten.uniq.sort - @params.keys.flatten.uniq.sort
    missing_commands.delete(:ensure)
    raise Puppet::Error, "Undefined commands for #{missing_commands.join(', ')}" unless missing_commands.empty?
    [is.keys, should.keys].flatten.uniq.sort.each do |property|
      next if property == :acl_type
      next if should[property] == :undef
      @params[property].value = :absent if should[property] == :absent || should[property].nil?
      @params[property].value = should[property] unless should[property] == :absent || should[property].nil?
    end
    before_update
    perform_update(is, should)
    after_update
  end

  #Called in update method and it adds vlan if ensure parameter is present else removes vlan.
  def perform_update(is, should)
    case @params[:ensure].value
    when :present
      transport.command("vlan #{name}", :prompt => /\(config-vlan#{name}\)#\s?\z/n)
      PuppetX::DellPowerconnect::Sorter.new(@params).tsort.each do |param|
        # We dont want to change undefined values
        next if should[param.name] == :undef || should[param.name].nil?
        # Skip the ensure property
        next if param.name == :ensure
        param.update(@transport, is[param.name]) unless is[param.name] == should[param.name]
      end
      transport.command("exit")
    when :absent
      transport.command("no vlan #{name}")
    else
      "default value"
    end
  end

  def mod_path_base
    return 'puppet_x/dell_powerconnect/model/vlan'
  end

  def mod_const_base
    return PuppetX::DellPowerconnect::Model::Vlan
  end

  def param_class
    return PuppetX::DellPowerconnect::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end
end
