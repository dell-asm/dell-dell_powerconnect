require 'puppet/util/network_device/dsl_powerconnect'
require 'puppet/util/network_device/dell_powerconnect/model'
require 'puppet/util/network_device/sorter'

# The Base model which is extended by model classes
# for each puppet type
class Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Base

  include Puppet::Util::NetworkDevice::Dsl_powerconnect

  attr_accessor :ensure, :name, :transport, :facts
  def initialize(transport, facts)
    @transport = transport
    @facts = facts
  end

  def update(is = {}, should = {})
    return unless configuration_changed?(is, should)
    missing_commands = [is.keys, should.keys].flatten.uniq.sort - @params.keys.flatten.uniq.sort
    missing_commands.delete(:ensure)
    raise Puppet::Error, "Undefined commands for #{missing_commands.join(', ')}" unless missing_commands.empty?
    [is.keys, should.keys].flatten.uniq.sort.each do |property|
      next if property == :ensure
      next if should[property] == :undef
      @params[property].value = :absent if should[property] == :absent || should[property].nil?
      @params[property].value = should[property] unless should[property] == :absent || should[property].nil?
    end
    before_update
    Puppet::Util::NetworkDevice::Sorter.new(@params).tsort.each do |param|
      # We dont want to change undefined values
      next if should[param.name] == :undef || should[param.name].nil?
      param.update(@transport, is[param.name]) unless is[param.name] == should[param.name]
    end
    after_update
  end

  def configuration_changed?(is, should, options = {})
    # Dup the Vars so we dont modify the orig. values
    is = is.dup.delete_if {|key,value| value == :undef || should[key] == :undef}
    is.delete_if {|key,value| key == :ensure} unless options[:keep_ensure]
    should = should.dup.delete_if {|key,value| value == :undef}
    should.delete_if {|key,value| key == :ensure} unless options[:keep_ensure]
    is != should
  end

  def mod_path_base
    raise Puppet::Error, 'Override me'
  end

  def mod_const_base
    raise Puppet::Error, 'Override me'
  end

  def param_class
    raise Puppet::Error, 'Override me'
  end

  def before_update
    transport.command("conf t", :prompt => /\(config\)#\s?\z/n)
  end

  def after_update
    txt = ''
    yesflag = false
    transport.command("end")
    transport.command("copy running-config startup-config") do |out|
    Puppet.debug("Copy config started")
	out.each_line do |line|
        if line.start_with?("Are you sure you want to save") && yesflag == false
          if transport.class.name.include?('Ssh')
            transport.send("y")
          else
            transport.send("y\r")
          end
          yesflag = true
        end
      end
      Puppet.debug("done")
      txt << out
    end
    item = txt.scan("Configuration Saved!")
    if item.empty?
      msg="Failed to save configuration."
      Puppet.debug(msg)
      raise msg
    else
      Puppet.debug("Configuration saved.")
    end
  end

  def get_base_cmd
    raise ArgumentError, "Base Command not set for #{self.class}" if base_cmd.nil?
    ERB.new(base_cmd).result(binding)
  end

  def construct_cmd
    base = get_base_cmd
    Puppet::Util::NetworkDevice::Sorter.new(@params).tsort.each do |param|
      fragment = param.get_fragment if param.fragment and param.value
      base << " #{fragment}" if fragment and param.supported?
    end
    return base
  end

  def perform_update
    case @params[:ensure].value
    when :present
      transport.command(construct_cmd)
    when :absent
      transport.command("no " + construct_cmd)
    else
      "do nothing."
    end
  end
end
