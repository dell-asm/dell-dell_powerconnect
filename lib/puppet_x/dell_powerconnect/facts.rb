require 'puppet_x/dell_powerconnect/sorter'
require 'puppet_x/dell_powerconnect/dsl'
require 'puppet_x/dell_powerconnect/fact'
require 'puppet_x/dell_powerconnect/possible_facts'
# Represents the inventory data for PowerConnect switch
# Individual facts are stored as Fact instances
class PuppetX::DellPowerconnect::Facts

  include PuppetX::DellPowerconnect::Dsl

  attr_reader :transport
  def initialize(transport)
    @transport = transport
  end

  def mod_path_base
    return 'puppet_x/dell_powerconnect/possible_facts'
  end

  def mod_const_base
    return PuppetX::DellPowerconnect::PossibleFacts
  end

  def param_class
    return PuppetX::DellPowerconnect::Fact
  end

  # TODO
  def facts
    @params
  end

  def facts_to_hash
    params_to_hash
  end
end
