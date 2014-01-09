require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'
require 'puppet/provider/powerconnect_messages'
require 'puppet/provider/powerconnect_responses'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods
  $dev = Puppet::Util::NetworkDevice.current
  
  def run(url, forceupdate, saveconfig)
    
    if exists(url) == true && forceupdate == false
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_VERSION_EXISTS_INFO)
      return
    else
      update(url)
    end
    
    if saveconfig == true 
      save_switch_config()
    end
   
    status = reboot_switch()
    
    if status == true
      ping_switch()
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_SUCCESSFUL_INFO)
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_ERROR
    end
    
    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_SUCCESSFUL_INFO)
    return status

  end
  
  def exists(url)
    currentfirmwareversion = $dev.switch.facts['Active_Software_Version']
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first
    Puppet.debug(Puppet::Provider::Powerconnect_messages::CHECK_FIRMWARE_VERSION_DEBUG%[currentfirmwareversion,newfirmwareversion])
    if currentfirmwareversion.to_s.strip.eql?(newfirmwareversion.to_s.strip)
      return true
    else
      return false
    end
  end
  
  
  def update(url)
    txt = ''
    image1version = ''
    image2version = ''
    bootimage = 'image2'
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first
    
    txt = download_image(url)
    item = txt.scan(Puppet::Provider::Powerconnect_responses::RESPONSE_IMAGE_DOWNLOAD_SUCCESSFUL)
    if item.empty?
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_IMAGE_DOWNLOAD_ERROR
    end

    $dev.transport.command('show version') do |out|
      out.scan(/^\d+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) do |arr|
        image1version = arr[0]
        image2version = arr[1]
      end
    end

    if image1version.eql?(newfirmwareversion)
      bootimage = "image1"
    else
      bootimage = "image2"
    end

    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_SET_BOOTIMAGE_DEBUG%[bootimage])
    $dev.transport.command('boot system ' + bootimage) do |out|
      txt << out
    end
    
  end
  
  def download_image(url)
    yesflag = false
    txt = ''
    
    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_DOWNLOAD_DEBUG)
    $dev.transport.command('copy ' + url + ' image') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_START_IMAGE_DOWNLOAD) && yesflag == false
          if $dev.transport.class.name.include?('Ssh')
            $dev.transport.send("y")
          else
            $dev.transport.send("y\r")
          end
          yesflag = true
        end
      end
      txt << out
    end
    return txt

  end
  
  def save_switch_config()
    yesflag = false
    txt = ''
    
    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_SAVE_CONFIG_INFO)
    $dev.transport.command('copy running-config startup-config') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_SAVE)&& yesflag == false
          $dev.transport.sendwithoutnewline("y")
          yesflag = true
        end
      end
      txt << out
    end
    
  end

  def reboot_switch()
    
    $dev.transport.command('update bootcode') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_REBOOT)
          $dev.transport.sendwithoutnewline("y")
        end
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_SAVE_BEFORE_REBOOT)
          $dev.transport.sendwithoutnewline("y")
        end
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_REBOOT_SUCCESSFUL)
          return true
        end
      end
    end
    
    return false
  end
  
  def ping_switch()
    #Sleep for 2 mins to wait for switch to come up
    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_REBOOT_INFO)
    sleep 120

    Puppet.info(Puppet::Provider::Powerconnect_messages::POWERCONNECT_PING_SWITCH_INFO)
    for i in 0..20
      if pingable()
        Puppet.debug(Puppet::Provider::Powerconnect_messages::POWERCONNECT_PING_SUCCESS_DEBUG)
        break
      else
        Puppet.info(Puppet::Provider::Powerconnect_messages::POWERCONNECT_RETRY_PING_INFO)
        sleep 60
      end
    end

    #Re-establish transport session
    $dev.connect_transport
    $dev.switch.transport=$dev.transport
    Puppet.debug(Puppet::Provider::Powerconnect_messages::POWERCONNECT_RECONNECT_SWITCH_DEBUG)
  end 
  
  def pingable()
    output = `ping -c 4 #{$dev.transport.host}`
    return (!output.include? "100% packet loss")
  end

end
