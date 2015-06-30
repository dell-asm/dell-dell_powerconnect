require 'puppet_x/dell_powerconnect/value_helper'

#Represents an individual inventory fact
class PuppetX::DellPowerconnect::Fact
  attr_accessor :name, :idx, :value, :evaluated
  extend PuppetX::DellPowerconnect::ValueHelper
  def initialize(name, transport, facts = nil, idx = 0, &block)
    @name = name
    @idx = idx
    @evaluated = false
    @transport = transport
    #Puppet.debug "Inside fact.rb: transport = #{transport} facts = #{facts}"
    self.instance_eval(&block)
  end

  define_value_method [:cmd, :match, :add, :remove, :before, :after, :match_param, :required]

  def parse(txt)
    param_match = self.match
    if param_match.is_a?(Proc)
      self.value = param_match.call(txt)
    else
      self.value = txt.scan(param_match).flatten[self.idx]
    end
    param_value = self.value
    self.evaluated = true
    raise Puppet::Error, "Fact: #{self.name} is required but didn't evaluate to a proper Value" if self.required == true && (param_value.nil? || param_value.to_s.empty?)
  end

end
