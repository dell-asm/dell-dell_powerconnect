require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods
  def run(url, forceupdate, saveconfig)
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    image1version = ''
    image2version = ''
    bootimage = 'image2'
    yesflaga = false
    yesflagb = false
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
        if line.start_with?("Are you sure you want to start") && yesflaga == false
          if dev.transport.class.name.include?('Ssh')
            dev.transport.send("y")
          else
            dev.transport.send("y\r")
          end
          yesflaga = true
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

    dev.transport.command('show version') do |out|
      out.scan(/^\d+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) do |arr|
        Puppet.debug "image1version = #{arr[0]}"
        Puppet.debug "image2version = #{arr[1]}"
        image1version = arr[0]
        image2version = arr[1]
      end
    end

    if image1version.eql?(newfirmwareversion)
      bootimage = "image1"
    else
      bootimage = "image2"
    end

    dev.transport.command('boot system ' + bootimage) do |out|
      txt << out
    end

    if saveconfig == :true
      dev.transport.command('copy running-config startup-config') do |out|
        out.each_line do |line|
          if line.start_with?("Are you sure you want to save")&& yesflagb == false
            dev.transport.sendwithoutnewline("y")
            yesflagb = true
          end
        end
        txt << out
      end
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
          dev.transport.sendwithoutnewline("y")
        end
        if line.start_with?("Are you sure you want to continue")
          dev.transport.sendwithoutnewline("y")
        end
        if line.start_with?("Validating boot code from image")
          Puppet.debug "Rebooting the switch.Wait for 5 minutes."
          return "Successful"
        end
      end
    end
    return "Failed"
  end

end
