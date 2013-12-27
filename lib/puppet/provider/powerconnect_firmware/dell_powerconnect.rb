require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods
  def run(url, forceupdate)
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    currentfirmwareversion = dev.switch.facts['Active_Software_Version']
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first
    Puppet.debug "Current Firmware Version #{currentfirmwareversion}"
    Puppet.debug "New Firmware Version #{newfirmwareversion}"
    Puppet.debug("ForceUpdate : #{forceupdate}")
    if currentfirmwareversion.to_s.strip.eql?(newfirmwareversion.to_s.strip) && forceupdate == :false
      txt = "Existing Firmware versions is same as new Firmware version, so skipping firmware update"
      Puppet.debug(txt)
      return txt
    end

    dev.transport.command('copy ' + url + ' image') do |out|
      out.each_line do |line|
        if line.start_with?("Are you sure you want to start")
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
    
    successmsg = "Firmware Update is successful."
    failedmsg = "Firmware Update Failed"
    status = rebootswitch()
    sleep 300
    status == "Successful" ? Puppet.debug(successmsg) : Puppet.debug(failedmsg)
    status == "Successful" ? (return successmsg) :(return failedmsg)

  end
  
  def rebootswitch()
    dev = Puppet::Util::NetworkDevice.current
    dev.transport.command('update bootcode') do |out|
      out.each_line do |line|
        if line.start_with?("Update bootcode and reset")
          dev.transport.send("y")
        end
        if line.start_with?("Are you sure you want to continue")
          dev.transport.send("y")
        end
        if line.start_with?("Validating boot code from image")
          Puppet.debug "Rebooting the switch."
          return "Successful"
        end
      end
    end
    return "Failed"
  end

end
