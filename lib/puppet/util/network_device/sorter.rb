require 'tsort'

class Puppet::Util::NetworkDevice::Sorter

  include TSort

  def initialize(param)
    @param = param
  end

  def tsort_each_node(&block)
    @param.each_value(&block)
  end

  def tsort_each_child(param, &block)
    @param.each_value.select  { |item|
      next unless item.respond_to?(:before) && item.respond_to?(:after)
      next unless param.respond_to?(:after)
      item.before == param.name || item.name == param.after
    }.each(&block)
  end
end
