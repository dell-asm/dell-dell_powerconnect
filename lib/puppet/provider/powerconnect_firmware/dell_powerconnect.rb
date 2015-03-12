require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'
require 'puppet/provider/powerconnect_messages'
require 'puppet/provider/powerconnect_responses'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do

  @doc = "Updates the PowerConnect switch firmware"

  mk_resource_methods
  def run(url, forceupdate, saveconfig)

    get_device()

    #Check if firmware by the same version already exists on switch
    if exists(url) == true && forceupdate == :false
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_VERSION_EXISTS_INFO)
      return
    else
      #Update switch firmware
      update(url)
    end

    if saveconfig == :true
      #Save any unsaved switch configuration changes before rebooting
      save_switch_config()
    end

    #Reboot so that switch boots with new firmware image
    status = reboot_switch()

    if status == true
      #Check if switch is back
      ping_switch()
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_SUCCESSFUL_INFO)
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_ERROR
    end

    if exists(url)
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_SUCCESSFUL_INFO)
      return status
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_UNSUCCESSFUL_INFO
    end
  end

  def exists(url)
    currentfirmwareversion = @device.switch.facts['Active_Software_Version']
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
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first

    txt = download_image(url)
    item = txt.scan(Puppet::Provider::Powerconnect_responses::RESPONSE_IMAGE_DOWNLOAD_SUCCESSFUL)
    if item.empty?
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_IMAGE_DOWNLOAD_ERROR
    end

    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_SET_BOOTIMAGE_DEBUG%['backup'])
    @transport.command('boot system backup') do |out|
      txt << out
    end

  end

  def download_image(url)
    yesflag = false
    txt = ''

    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_DOWNLOAD_DEBUG)
    @transport.command('copy ' + url + ' backup') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_START_IMAGE_DOWNLOAD) && yesflag == false
          if @transport.class.name.include?('Ssh')
            @transport.send("y")
          else
            @transport.send("y\r")
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

    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_SAVE_CONFIG_INFO)
    @transport.command('copy running-config startup-config') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_SAVE)&& yesflag == false
          @transport.sendwithoutnewline("y")
          yesflag = true
          return true
        end
      end
      txt << out
    end
    raise Puppet::Error, "Error reloading server: #{txt}"
  end

  def reboot_switch()
    yesflag = false
    txt = ''

    Puppet.info("Rebooting the switch")
    @transport.command('reload') do |out|
      out.each_line do |line|
        if line.include?(Puppet::Provider::Powerconnect_responses::RESPONSE_REBOOT_VERIFY_REBOOT) && yesflag == false
          @transport.sendwithoutnewline("y")
          yesflag = true
        end
      end
      txt << out
    end
    true
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
    @device.connect_transport
    @device.switch.transport=@transport
    Puppet.debug(Puppet::Provider::Powerconnect_messages::POWERCONNECT_RECONNECT_SWITCH_DEBUG)
  end

  def pingable()
    output = `ping -c 4 #{@transport.host}`
    return (!output.include? "100% packet loss")
  end

  def get_device()
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Dell_powerconnect: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new(Facter.value(:url))
      @device.init
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Dell_powerconnect: device not initialized" unless @device
    end
    @transport = @device.transport
    return @device
  end

end
