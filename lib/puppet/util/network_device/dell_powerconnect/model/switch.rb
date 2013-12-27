require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/vlan'
require 'puppet/util/network_device/dell_powerconnect/model/portchannel'
require 'puppet/util/network_device/dell_powerconnect/model/base'
require 'puppet/util/network_device/dell_powerconnect/model/generic_value'

class Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch < Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Base

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
    return 'puppet/util/network_device/dell_powerconnect/model/switch'
  end

  def mod_const_base
    return Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch
  end

  def param_class
    return Puppet::Util::NetworkDevice::Dell_powerconnect::Model::GenericValue
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
  ].each do |key|
    define_method key.to_s do |name|
      grp = params[key].value.find { |group| group.name == name }
      if grp.nil?
        grp = Puppet::Util::NetworkDevice::Dell_powerconnect::Model.const_get(key.to_s.capitalize).new(transport, facts, {:name => name})
        params[key].value << grp
      end
      grp.evaluate_new_params
      return grp
    end
  end

end
