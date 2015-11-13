require 'puppet_x/dell_powerconnect/possible_facts'
require 'json'

module PuppetX::DellPowerconnect::PossibleFacts::Base
  def self.register(base)

    base.register_param 'machinetype' do
      match do |txt|
        txt.scan(/^Machine\s+Type:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end

    base.register_param 'system_description' do
      match do |txt|
        txt.scan(/^System\s+Description:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end

    base.register_param 'bootimage' do
      res = ''
      match do |txt|
        txt.scan(/^\d+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) do |arr|
          res = arr[2]
        end
        res
      end
      cmd 'show bootvar'
    end

    base.register_param 'model' do
      match do |txt|
        txt.scan(/^System\s+Model\s+ID:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end

    base.register_param 'systemuptime' do
      match do |txt|
        txt.scan(/^System\s+Up\s+Time:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end

    base.register_param 'hostname' do
      match /^hostname\s+(\S+)$/
      cmd 'show running-config | grep hostname'
    end

    base.register_param 'defaultdomain' do
      match do |txt|
        txt.scan(/^Default\s+domain:\s+(.+)$/).flatten.first
      end
      cmd 'show hosts'
    end

    base.register_param 'servicetag' do
      match do |txt|
        txt.scan(/^Service\s+Tag:\s+(.+)$/).flatten.first
      end
      cmd 'show system id'
    end

    base.register_param 'assettag' do
      match do |txt|
        txt.scan(/^Asset\s+Tag:\s+(.+)$/).flatten.first
      end
      cmd 'show system id'
    end

    base.register_param 'serialnumber' do
      match do |txt|
        txt.scan(/^Serial\s+Number:\s+(.+)$/).flatten.first
      end
      cmd 'show system id'
    end

    base.register_param 'totalmemory' do
      match do |txt|
        txt.scan(/^Total Memory[.]+\s+(.+)$/).flatten.first
      end
      cmd 'show memory cpu'
    end

    base.register_param 'availablememory' do
      match do |txt|
        txt.scan(/^Available Memory Space[.]+\s+(.+)$/).flatten.first
      end
      cmd 'show memory cpu'
    end

    base.register_param 'switchstate' do
      state = 'Unknown'
      match do |txt|
        txt.scan(/(.*)\s+(\w+)\s+(\d.+)$/) do |arr|
          state = arr[1]
        end
        state
      end
      cmd 'show switch'
    end

    base.register_param 'powerstate' do
      match do |txt|
        txt.scan(/^[\d+]\s+System\s+(\S+)/).flatten.first
      end
      cmd 'show system power'
    end

    base.register_param 'macaddress' do
      match do |txt|
        txt.scan(/^Burned\s+In\s+MAC\s+Address:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end

    base.register_param 'managementip' do
      match do |txt|
        @transport.host
      end
      cmd 'show ip interface'
    end

    base.register_param 'interfaces' do
      all_interfaces = ''
      match do |txt|
        txt.each_line do |line|
          line.scan(/^[a-zA-Z]+[0-9\/]+/) do |item|
            if all_interfaces.to_s != ''
              all_interfaces = all_interfaces + ","
            end
            all_interfaces = all_interfaces + item
          end
        end
        all_interfaces
      end
      cmd 'show interfaces status'
    end

    base.register_param ['interfaces_gigabitethernet'] do
      count = 0
      match do |txt|
        txt.each_line do |line|
          line.scan(/^Gi[0-9\/]+/) do |item|
            count = count + 1
          end
        end
        count.to_s
      end
      cmd 'show interfaces status'
    end

    base.register_param ['interfaces_tengigabitethernet'] do
      count = 0
      match do |txt|
        txt.each_line do |line|
          line.scan(/^Te[0-9\/]+/) do |item|
            count = count + 1
          end
        end
        count.to_s
      end
      cmd 'show interfaces status'
    end

    base.register_param 'vlan' do
      vlan_conf = ''
      match do |txt|
        txt.each_line do |line|
          line.scan(/^[0-9]+/) do |item|
            #Puppet.debug "item = #{item}"
            if vlan_conf.to_s != ''
              vlan_conf = vlan_conf + ","
            end
            vlan_conf = vlan_conf + item
          end
        end
        vlan_conf
      end
      cmd "show vlan"
    end

    base.register_param 'vlandata' do
      res = Hash.new
      vlan_data = Hash.new
      vlan_attrs_global = Hash.new
      match do |txt|
        index = 0
        linenum = 0
        newvlan = true
        txt.each_line do |line|
          if linenum > 3 then
            confvlans = base.facts['vlan'].value.split(',')
            numbered_lines = line.scan(/[0-9]\s+(.+)/).flatten.compact
            if numbered_lines[0].to_s != '' then
              vlan_attrs = Hash.new
              vlan_data[confvlans[index].to_s] = vlan_attrs
              line.scan(/[0-9]\s+(.+)/) do |item|
                attributes = item[0].gsub(/[ \r\t\n]+/, ' ').strip.split(' ')
                vlan_attrs["name"] = attributes[0]
                vlan_attrs["type"] = attributes[2]
                vlan_attrs["ports"] = attributes[1]
                vlan_attrs_global = vlan_attrs
                index = index+1
              end
            else
              justports = line.gsub(/[ \r\t\n]+/, ' ').strip
              if justports.count('#') == 0 then
                vlan_attrs_global["ports"] = vlan_attrs_global["ports"] + justports
              end
            end
            linenum = linenum +1
          else
            linenum = linenum + 1
          end

        end
        res["vlandata"] = vlan_data.to_json
        res
      end
      cmd "show vlan"
    end

    base.register_param 'interfacedata' do
      res = Hash.new
      interface_data = Hash.new
      match do |txt|
        txt.scan(/^interface ((Gi|Te)[0-9\/]+)\n(description (.*)\n)?(channel-group (.*)\n)?(shutdown\n)?(spanning-tree (.*)\n)?mtu (.*)\n(switchport mode (.*)\n)?(switchport (.*) allowed vlan add (.*) tagged\n)?(switchport access vlan (.*)\n)?exit$/) do |item|
          interface_attrs = Hash.new
          #interface_attrs["mtu"] = item[9]
          if item[14] != nil then
            Puppet.debug "TaggedVlans #{item[14]}"
            interface_attrs["TaggedVlans"] = item[14]
          end
          if item[16] != nil then
            interface_attrs["TaggedVlans"] = item[16]
          end
          interface_data[item[0]] = interface_attrs
        end
        res["interfacedata"] = interface_data.to_json
        res
      end
      cmd 'show running-config'
    end

    base.register_param 'portchannelstatus' do
      res = Hash.new
      portchannels = Hash.new
      match do |txt|
        txt.scan(/^(Po[0-9]+)[a-zA-Z0-9 ]+\s+\d+\s+(\S+)$/) do |arr|
          portchannels[arr[0]] = arr[1]
        end
        res["portchannelstatus"] = portchannels.to_json
        res
      end
      cmd 'show interfaces configuration'
    end

    base.register_param 'portchannelmap' do
      res = Hash.new
      portchannels = Hash.new
      match do |txt|
        txt.scan(/^(Po[0-9]+)\s+(Active: |Inactive: )([(Te|Gi)[0-9\/]+, ]+)/) do |arr|
          portchannels[arr[0]] = arr[2]
        end
        res["portchannelmap"] = portchannels.to_json
        res
      end
      cmd 'show interfaces port-channel'
    end

    base.register_param 'remote_device_info' do
      res = Hash.new
      remote_device = nil
      remote_device_info_list = []
      match do |txt|
        txt.split(/\n+/).each_with_index do |line, i|
          #Line will be something like "Te1/0/5   29      AA:BB:CC:DD:EE:FF   eth0                name"
          next if i < 5  # Skip the first 5 lines (headers)
          tokens = line.scan(/\S+/)
          next unless tokens.size == 5

          interface = tokens[0]
          location = tokens[3]
          remote_mac = tokens[2]
          remote_system_name = tokens[4]

          next unless remote_mac =~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/i

          remote_device = {:interface => interface, :location => location, :remote_mac => remote_maca ,:remote_system_name => remote_system_name}
          remote_device_info_list << remote_device
        end
        res["remote_device_info"] = remote_device_info_list.uniq.to_json
        res
      end
        cmd 'show lldp remote-device all'
    end

    base.register_param 'remotedeviceinfo' do
      res = Hash.new
      devices = Hash.new
      match do |txt|
        txt.split(/\n+/).each do |line|
          #Line will be something like "Te1/0/5   29      AA:BB:CC:DD:EE:FF   eth0                name"
          tokens = line.scan(/\S+/)
          port = tokens[0]
          mac = tokens[2]
          devices[mac] = port
        end
        # Commenting remote hash information as mac-address information is
        # listing from other switches via inter-switch link
        res["remotedeviceinfo"] = devices.to_json
      end
      cmd 'show lldp remote-device all'
    end

    base.register_param 'Active_Software_Version' do
      match do |txt|
        txt.scan(/System\sSoftware\sVersion\s+(.+)/).flatten.first
      end
      cmd 'show running-config'
    end

  end
end
