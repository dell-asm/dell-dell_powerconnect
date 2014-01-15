require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'
require 'puppet/provider/powerconnect_messages'

#begin
#  module_path = Puppet::Module.find('asm_lib', Puppet[:environment].to_s)
#  require File.join module_path.path, 'lib/i18n/AsmException'
#  require File.join module_path.path, 'lib/i18n/AsmLocalizedMessage'
#end

$CALLER_MODULE = "dell_powerconnect"

Puppet::Type.type(:powerconnect_config).provide :dell_powerconnect, :parent => Puppet::Provider do

  @doc = "Updates the running-config and startup-config of PowerConnect switch"

  mk_resource_methods
  def run(url, config_type, force)
    #begin
    digestlocalfile=''
    digestserverconfig=''
    extBackupConfigfile = ''
    flashtmpfile = 'flash://backup-configtemp.scr'
    backedupPrevConfig = false
    yesflag = false
    txt = ''

    @dev = Puppet::Util::NetworkDevice.current

    ##first check whether there is any backup-config, if so store it to flash and restore it at the end
    backedupPrevConfig = preUpdateBackupConfigSave(url, flashtmpfile)

    digestlocalfile = getBackupConfigMD5
    digestserverconfig = getSwitchConfigMD5(config_type)
    Puppet.debug "digest1 = #{digestlocalfile} && digest2 = #{digestserverconfig}"

    if digestlocalfile != digestserverconfig || force == :true
      applyConfig(url, config_type)
    end

    Puppet.debug "force is #{force}"

    if digestlocalfile.eql?(digestserverconfig) && force == :false
      Puppet.info(Puppet::Provider::Powerconnect_messages::CONFIG_CONFIGS_MATCH_NO_FORCE)
    end

    cleanupBackupConfig
    if backedupPrevConfig == true
      restoreOldBackupConfig(flashtmpfile)
    end

    if config_type == 'startup' && (digestlocalfile != digestserverconfig || force == :true)
      startupconfigPostUpdate
    end
    #    rescue AsmException => ae
    #      ae.log_message
    #    rescue Exception => e
    #      AsmException.new("ASM001", $CALLER_MODULE, e).log_message
    #end
  end

  def applyConfig(url, config_type)
    Puppet.info("Applying the configuration")
    executeCommand('copy '+ url +" "+ config_type+'-config',"Are you sure you want to start")
  end

  def preUpdateBackupConfigSave(url, flashtmpfile)
    backedupPrevConfig = false
    extBackupConfigfile = ''

    @dev.transport.command('show backup-config') do |extBackup|
      extBackupConfigfile<< extBackup
    end
    if extBackupConfigfile.include? "Configuration script 'backup-config' not found"
      ##There is no existing backup config so do nothing
      Puppet.debug "no previous backup config found"
    else
      ##There is an existing backup config
      Puppet.debug "There is a previous backup config found"
      saveBackupConfig(flashtmpfile)
      backedupPrevConfig = true
    end
    ##copying the file from tftp to backup-config
    executeCommand('copy ' + url + ' backup-config',"Are you sure you want to start")
    return backedupPrevConfig
  end

  def cleanupBackupConfig
    executeCommand('delete backup-config',"Delete ")
  end

  def getSwitchConfigMD5(config)
    digest = getfileMD5(config+'-config', 0..19)
    return digest
  end

  def getBackupConfigMD5
    digestlocalfile = getfileMD5('backup-config', 0..18)
    Puppet.debug "digest1 = #{digestlocalfile}"
    if digestlocalfile != 0
      Puppet.debug "File transfer successful"
    else
      Puppet.info "failed to copy the file from the server"
      #raise AsmException.new("ASM004", $CALLER_MODULE, nil, nil)
      raise "Failed to copy the configuration file from the server."
    end
    return digestlocalfile
  end

  def startupconfigPostUpdate
    Puppet.debug "Doing a reload"
    reloadswitch
    ping_switch
    initializeswitch
  end

  def restoreOldBackupConfig(flashtmpfile)
    Puppet.debug "Restoring the previous backup config"
    #Restoring the backed up backed up backup config
    executeCommand('copy ' + flashtmpfile+ ' backup-config',"Are you sure you want to start")
    # deleting the backup file from flash
    Puppet.debug "Deleting the backup file"
    executeCommand('delete backup-configtemp.scr',"Delete ")
  end

  def executeCommand(cmd, str)
    yesflag = false
    @dev.transport.command(cmd) do |out|
      out.each_line do |line|
        if line.include?(str) && yesflag == false
          if @dev.transport.class.name.include?('Ssh')
            command = "y"
          else
            command = "y\r"
          end
          @dev.transport.send(command)
          yesflag = true
        end
      end
    end
  end

  def getfileMD5(configtype, slice)
    filecontent = ''
    @dev.transport.command('show '+configtype) do |out|
      Puppet.debug "I am here4"
      filecontent<< out
      Puppet.debug "out = #{out}"
    end
    compareStr = "Configuration script "+"'"+configtype+"'"+" not found"
    if filecontent.include? compareStr
      digestlocalfile = 0
      return digestlocalfile
    end

    if @dev.transport.class.name.include? 'Telnet'
      filecontent.slice!(slice)
    else
      if @dev.transport.class.name.include? 'Ssh'
        index = filecontent.rindex("!Current Configuration")
        filecontent = filecontent[index..-1]
        Puppet.debug "I am here5"
      else
      end
    end
    digestlocalfile = Digest::MD5.hexdigest(filecontent)
    return digestlocalfile
  end

  def reloadswitch()
    yesflag = false
    doubleflag = false
    @dev.transport.command('reload') do |out|
      out.each_line do |line|
        if line.start_with?("Are you sure you want to continue") && yesflag == false
          @dev.transport.sendwithoutnewline("yy")
          yesflag = true
          doubleflag = true
        end
        if line.start_with?("Are you sure you want to reload the stack")
          if doubleflag == false
            @dev.transport.command('y') do |out|
              break
            end
          end
          return
        end
      end
    end
  end

  def initializeswitch
    @dev = Puppet::Util::NetworkDevice.current
    #Reesatblish transport session
    Puppet.info("Trying to reconnect to switch...")
    @dev.connect_transport
    @dev.switch.transport=@dev.transport
    Puppet.info("Session established...")
  end

  def getBackupConfig
    fileOut = ''
    @dev.transport.command('show backup-config') do |extBackup|
      fileOut<< extBackup
    end
    return fileOut
  end

  def saveBackupConfig(tmpfile)
    executeCommand('copy backup-config ' + tmpfile,"Are you sure you want to start")
    executeCommand('delete backup-config',"Delete backup-config (Y/N)")
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
  end

  def pingable()
    output = `ping -c 4 #{@dev.transport.host}`
    Puppet.debug "ping output = #{output}"
    return (!output.include? "100% packet loss")
  end

end