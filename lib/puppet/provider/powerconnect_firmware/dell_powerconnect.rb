require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, forceupdate)   
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    Puppet.debug "please"
    currentFirmwareVersion = dev.switch.facts['Active_Software_Version']
    Puppet.debug "current = #{currentFirmwareVersion}"
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first
    Puppet.debug "new = #{newfirmwareversion}"
    if currentFirmwareVersion.eql? newfirmwareversion && forceupdate == :false
      txt = "Existing Firmware versions is same as new Firmware version, so not doing firmware update"
      return txt
    end
    
    dev.transport.command('copy ' + url + ' image') do |out|
      Puppet.debug "out = #{out}"
      out.each_line do |line|
        if line.start_with?("Are you sure you want to start")
          Puppet.debug "hello2"
          dev.transport.send("y\r") 
        end
      end
      txt << out
    end
    
    item = txt.scan("File transfer operation completed successfully")
    if item.empty?
      msg="Firmware update is not successful"
      Puppet.debug(msg)
      raise msg 
    end
      
    dev.transport.command('boot system image2') do |out|
      txt << out
    end
    
    dev.transport.command('update bootcode') do |out|
      out.each_line do |line|
        if line.start_with?("Update bootcode and reset")
          dev.transport.send("y") 
        end 
        if line.start_with?("Are you sure you want to continue")
          dev.transport.send("y") 
        end
      end
      txt << out
    end 
    
    item = txt.scan("CRC Valid")
    if item.empty?
      msg="Firmware update is not successful. Failed to update bootcode and reboot switch"
      Puppet.debug(msg)
      raise msg 
    end  
    
    sleep 600
    
    return txt
  end
  
end
