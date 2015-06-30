#Module for configuring facts on the switch device
require 'puppet_x/dell_powerconnect/model/base'
require 'puppet_x/dell_powerconnect/model/vlan'
require 'puppet_x/dell_powerconnect/model/portchannel'
require 'puppet_x/dell_powerconnect/model/generic_value'

class PuppetX::DellPowerconnect::Model::Switch < PuppetX::DellPowerconnect::Model::Base

  attr_reader :params, :vlans
  def initialize(transport, facts)
    super
    # Initialize some defaults
    @params         ||= {}
    @vlans          ||= []
    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def mod_path_base
    return 'puppet_x/dell_powerconnect/model/switch'
  end

  def mod_const_base
    return PuppetX::DellPowerconnect::Model::Switch
  end

  def param_class
    return PuppetX::DellPowerconnect::Model::GenericValue
  end

  def register_modules
    register_new_module(:base)
  end

  def skip_params_to_hash
    [ :snmp, :archive ]
  end

  def interface(name)
    int = params[:interfaces].value.find { |int| int.name == name }
    int.evaluate_new_params
    return int
  end

  [
    :vlan,
    :portchannel,
    :interface,
  ].each do |key|
    define_method key.to_s do |name|
      grp = params[key].value.find { |group| group.name == name }
      if grp.nil?
        grp = PuppetX::DellPowerconnect::Model.const_get(key.to_s.capitalize).new(transport, facts, {:name => name})
        params[key].value << grp
      end
      grp.evaluate_new_params
      return grp
    end
  end

end
