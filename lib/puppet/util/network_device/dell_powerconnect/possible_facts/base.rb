require 'puppet/util/network_device/dell_powerconnect/possible_facts'

module Puppet::Util::NetworkDevice::Dell_powerconnect::PossibleFacts::Base
  def self.register(base)

    base.register_param 'machinetype' do
      match do |txt|
        txt.scan(/^Machine\s+Type:\s+(.+)$/).flatten.first
      end
      cmd 'show system'
    end
    
    base.register_param 'systemmodelid' do
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
      match do |txt|
        txt.scan(/^Host\s+name:\s+(.+)$/).flatten.first
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
    
#    base.register_param 'vlan_attributes' do
#      res = Hash.new
#      match do |txt|
#        i = 0
#        lineNum = 0
#        txt.each_line do |line|
#          if lineNum > 3 then
#            confvlans = base.facts['vlan'].value.split(',')
#            numbered_lines = line.scan(/[0-9]\s+(.+)/).flatten.compact
#            if numbered_lines[0].to_s != '' then
#              line.scan(/[0-9]\s+(.+)/) do |item|            
#                attributes = item[0].gsub(/[ \r\t\n]+/, ' ').strip.split(' ')
#                res["vlan_"+confvlans[i]+"_attributes"] = "name = "+attributes[0]+" , "+"type = "+attributes[2]
#                res["vlan_"+confvlans[i]+"_Ports"] = attributes[1]     
#                i = i+1      
#              end  
#            else
#              justports = line.gsub(/[ \r\t\n]+/, ' ').strip
#              if justports.count('#') == 0 then 
#                res["vlan_"+confvlans[i-1]+"_Ports"] = res["vlan_"+confvlans[i-1]+"_Ports"] + justports
#              end
#            end            
#            lineNum = lineNum +1
#          else
#            lineNum = lineNum + 1
#          end 
#
#        end
#        res
#      end      
#      cmd "show vlan"      
#    end

    base.register_param 'Active_Software_Version' do
      match do |txt|
        txt.scan(/System\sSoftware\sVersion\s+(.+)/).flatten.first
      end
      cmd 'show running-config'
    end
  
  end
end
