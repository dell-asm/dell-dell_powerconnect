#Module for parsing model value
require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/dell_powerconnect/model/generic_value'

class Puppet::Util::NetworkDevice::Dell_powerconnect::Model::ModelValue < Puppet::Util::NetworkDevice::Dell_powerconnect::Model::GenericValue

  def model(*args, &block)
    return @model if args.empty? && block.nil?
    @model = (block.nil? ? args.first : block)
  end

  def parse(txt)
    if self.match.is_a?(Proc)
      self.value = self.match.call(txt)
    else
      self.value = txt.scan(self.match).flatten.collect { |name| model.new(@transport, @facts, { :name => name } ) }
    end
    self.value ||= []
    self.evaluated = true
  end

  def update(transport, old_value)
    Puppet.debug "Inside model_value.rb: transport = #{transport} old_value = #{old_value}"
  end
end
