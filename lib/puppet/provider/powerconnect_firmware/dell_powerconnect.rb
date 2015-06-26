require 'puppet/provider/dell_powerconnect'
require 'puppet/provider/powerconnect_messages'
require 'puppet/provider/powerconnect_responses'
require 'puppet_x/dell_powerconnect/transport'

Puppet::Type.type(:powerconnect_firmware).provide :dell_powerconnect, :parent => Puppet::Provider do

  @doc = "Updates the PowerConnect switch firmware"

  mk_resource_methods
  def run(url, forceupdate, saveconfig)

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
      save_switch_config
    end

    #Reboot so that switch boots with new firmware image
    status = reboot_switch

    if status
      #Check if switch is back
      ping_switch
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_SUCCESSFUL_INFO)
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_ERROR
    end
    if check_active_version(url)
      Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_SUCCESSFUL_INFO)
      return status
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_UNSUCCESSFUL_INFO
    end
  end

  def exists(url)
    currentfirmwareversion = transport.switch.facts['Active_Software_Version']
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first
    Puppet.debug(Puppet::Provider::Powerconnect_messages::CHECK_FIRMWARE_VERSION_DEBUG%[currentfirmwareversion,newfirmwareversion])
    if currentfirmwareversion.to_s.strip.eql?(newfirmwareversion.to_s.strip)
      return true
    else
      return false
    end
  end

  def check_active_version(url)
    txt = ''
    current_firmware = ''
    new_firmware = url.split("\/").last.split("v").last.split(".stk").first
    session.command('show version 1 | section active') do |out|
      txt << out
    end
    txt.each_line do |line|
      if line.start_with? '1'
        current_firmware = line.split(' ')[1]
      end
    end
    if current_firmware.to_s.strip.eql?(new_firmware.to_s.strip)
      true
    else
      false
    end
  end

  def update(url)
    txt = ''
    newfirmwareversion = url.split("\/").last.split("v").last.split(".stk").first

    txt = download_image(url)
    if txt.include? Puppet::Provider::Powerconnect_responses::RESPONSE_IMAGE_DOWNLOAD_SUCCESSFUL
    elsif txt.include? Puppet::Provider::Powerconnect_responses::RESPONSE_IMAGE_DOWNLOAD_SUCCESS2
    else
      raise Puppet::Error, Puppet::Provider::Powerconnect_messages::FIRMWARE_IMAGE_DOWNLOAD_ERROR
    end

    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPADTE_SET_BOOTIMAGE_DEBUG%['backup'])
    session.command('boot system backup') do |out|
      txt << out
    end

  end

  def download_image(url)
    yesflag = false
    txt = ''

    Puppet.debug(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_DOWNLOAD_DEBUG)
    session.command('copy ' + url + ' backup') do |out|
      out.each_line do |line|
        if line.start_with?(Puppet::Provider::Powerconnect_responses::RESPONSE_START_IMAGE_DOWNLOAD) && yesflag == false
          if session.class.name.include?('Ssh')
            session.send("y")
          else
            session.send("y\r")
          end
          yesflag = true
        end
      end
      txt << out
    end
    return txt

  end

  def save_switch_config
    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_SAVE_CONFIG_INFO)
    session.command('copy running-config startup-config', :prompt => /#{Puppet::Provider::Powerconnect_responses::RESPONSE_SAVE}/)
    session.command('y')
  end

  def reboot_switch
    Puppet.info("Rebooting the switch")
    session.command('reload', :prompt=>/#{Puppet::Provider::Powerconnect_responses::RESPONSE_REBOOT_VERIFY_REBOOT}/)
    #Session will terminate after sending yes/y, so we break as soon as we send so no connection error happens.
    session.command('y') {|out| break}
    true
  end

  def ping_switch
    #Sleep for 2 mins to wait for switch to come up
    Puppet.info(Puppet::Provider::Powerconnect_messages::FIRMWARE_UPDATE_REBOOT_INFO)
    sleep 120

    Puppet.info(Puppet::Provider::Powerconnect_messages::POWERCONNECT_PING_SWITCH_INFO)
    for i in 0..20
      if pingable?
        Puppet.debug(Puppet::Provider::Powerconnect_messages::POWERCONNECT_PING_SUCCESS_DEBUG)
        break
      else
        Puppet.info(Puppet::Provider::Powerconnect_messages::POWERCONNECT_RETRY_PING_INFO)
        sleep 60
      end
    end

    #Re-establish transport session
    transport.connect_session
    transport.switch.transport=transport.session
    Puppet.debug(Puppet::Provider::Powerconnect_messages::POWERCONNECT_RECONNECT_SWITCH_DEBUG)
  end

  def pingable?
    output = `ping -c 4 #{session.host}`
    return (!output.include? "100% packet loss")
  end

  def transport
    @transport ||= PuppetX::DellPowerconnect::Transport.new(Puppet[:certname])
  end

  def session
    transport.session
  end

end
