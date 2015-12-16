require 'puppet_x/dell_powerconnect/sorter'

module PuppetX::DellPowerconnect::Dsl
  def register_param(params, klass = nil, &block)
    # Make it so that we can register multiple Params at the same time
    # and assign every Param an index number that must match the Regex
    klass ||= param_class
    @params ||= {}
    [params].flatten.each_with_index do |param, idx|
      @params[param] = klass.new(param, transport, facts, idx, &block)
    end
  end

  def register_scoped(params, scope_match, klass = nil, &block)
    int_name = name
    register_param(params, klass) do
      raise "no name set" if name.nil?
      scope scope_match
      scope_name int_name
      # Pass the Block to a Helper Method so we are in the right Scope
      # when evaluating the block
      evaluate &block
    end
  end

  def params_to_hash
    @params.inject({}) {|res, data|
      unless respond_to?(:skip_params_to_hash) && skip_params_to_hash.include?(data[0])
        unless data[1].value.nil? || data[1].value.to_s.empty?
          if data[1].value.is_a?(Hash)
            res.merge!(data[1].value)
          else
            res[data[0]] = data[1].value
          end
        end
      end
      res
    }
  end

  def register_module_after(param, mod, path_addition = "", &block)
    # Register a new Module after the required Fact has been evaluated
    # Pass a Block that must evaluate to true or false to make sure we dont
    # include Modules by accident
    @after_hooks ||= {}
    @after_hooks[param] ||= []
    @after_hooks[param] << {:mod => mod, :path_addition => path_addition, :block => block}
  end

  def register_new_module(mod, path_addition = "")
    @included_modules ||= []
    unless @included_modules.include?(mod)
      Puppet::Util::Autoload.new(self, File.join(mod_path_base, path_addition), :wrap => false).load(mod)
      if path_addition.empty?
        mod_const_base.const_get(mod.to_s.capitalize).register(self)
        @included_modules << mod
      else
        mod_const_base.const_get(path_addition.to_s.capitalize).const_get(mod.to_s.capitalize).register(self)
        @included_modules << mod
      end
    end
  end

  def evaluate_new_params
    PuppetX::DellPowerconnect::Sorter.new(@params).tsort.each do |param|
      #Skip if the param has already been evaluated
      next if param.evaluated
      if param.cmd != false
        # Let the Transport Cache the Command for us since we are only dealing here with 'show' type commands
        out = @transport.command(param.cmd, :cache => true, :noop => false)
        # This is here for the Specs
        # FIXME
        if out.nil?
          param.evaluated = true
          next
        end
        param.parse(out)
      elsif param.match_param.is_a? Array
        param.parse([param.match_param].flatten.collect{|item|@params[item].value})
      else
        param.parse(@params[param.match_param].value)
      end
      @after_hooks ||= {}
      if @after_hooks[param.name]
        @after_hooks[param.name].each do |mod|
          register_new_module(mod[:mod], mod[:path_addition]) if mod[:block].call
        end
      end
    end
    evaluate_new_params unless @params.each_value.select {|param| param.evaluated == false}.empty?
  end

  def retrieve
    register_new_module(:base)
    evaluate_new_params
    params_to_hash
  end

  # register a simple param using the specified regexp and commands
  def register_simple(param, match_re, fetch_cmd, cmd)
    register_param param do
      match match_re
      cmd fetch_cmd
      add  do |transport, value|
        transport.command("#{cmd} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{cmd} #{old_value}")
      end
    end
  end

  # register a model based param
  def register_model(param, klass, match_re, fetch_cmd)
    register_param param, PuppetX::DellPowerconnect::Model::ModelValue do
      model klass
      match match_re
      cmd fetch_cmd
    end
  end

  # register a simple yes/no param. the regexp must match if the param is present
  def register_bool(param, match_re, fetch_cmd, cmd)
    register_param param do
      match do |txt|
        if !!txt.match(match_re)
          :present
        else
          :absent
        end
      end
      cmd fetch_cmd
      add do |transport, _|
        transport.command(cmd)
      end
      remove do |transport, _|
        transport.command("no #{cmd}")
      end
    end
  end

  # register a simple array-valued param
  # transform the array using a block if necessary
  def register_array(param, match_re, fetch_cmd, cmd, &block)
    register_param param do
      match do |txt|
        result = txt.scan(match_re).flatten
        if block_given?
          yield result
        else
          result
        end
      end
      cmd fetch_cmd
      add do |transport, value|
        transport.command("#{cmd} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{cmd} #{old_value}")
      end
    end
  end

  def vlan_data
    {
      "tagged_tengigabit" => [],
      "untagged_tengigabit" => [],
      "tagged_fortygigabit" => [],
      "untagged_fortygigabit" => [],
      "tagged_portchannel" => [],
      "untagged_portchannel" =>[]
    }
  end

  def vlan_information(txt)
    vlans = {}
    interface_id = nil
    txt.split(/\n+/).each_with_index do |line, i|
      next if i < 5 #skip headers
      tokens = line.scan(/\S+/)
      next if tokens[-2] == "T"
      if tokens.size == 1
        port_groups = tokens[0].split(",")
        port_group_parser(port_groups, vlans, interface_id)
      elsif tokens.size > 7
        interface_id = tokens[0]
        port_groups = tokens.last.split(",")
        port_group_parser(port_groups, vlans, interface_id)
      end
    end
    #Clean up data
    vlans.each do |vlan, data|
      data.each do |type, ports|
        next unless ports
        if ports.empty?
          ports = ""
        else
          ports = ports.uniq.join(",") if ports.class == Array
        end
        data[type] = ports
      end
    end
    vlans
  end

  def port_group_parser(port_groups,vlans, interface_id)
    port_groups.each do |group|
      vlan_group = group.scan(/(\d*-*\d*)/).flatten.reject{|c| c.empty?}[0]
      next if vlan_group.nil?
      vlan_set = []
      if vlan_group.include? "-"
        first = vlan_group.split("-")[0].to_i
        last = vlan_group.split("-")[1].to_i
        (first..last).each do |i|
          vlan_set << i.to_s
        end
      else
        vlan_set << vlan_group
      end
      vlan_set.each do |v|
        vlans[v] ||= vlan_data
        if group.include? "("
          vlans[v]["untagged_tengigabit"] << interface_id if interface_id.start_with? "Te"
          vlans[v]["untagged_fortygigabit"] << interface_id if interface_id.start_with? "Fo"
        else
          vlans[v]["tagged_tengigabit"] << interface_id if interface_id.start_with? "Te"
          vlans[v]["tagged_fortygigabit"] << interface_id if interface_id.start_with? "Fo"
        end
      end
    end
  end
end
