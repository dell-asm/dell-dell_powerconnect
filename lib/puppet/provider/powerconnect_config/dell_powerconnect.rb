require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

#begin
#  module_path = Puppet::Module.find('asm_lib', Puppet[:environment].to_s)
#  require File.join module_path.path, 'lib/i18n/AsmException'
#  require File.join module_path.path, 'lib/i18n/AsmLocalizedMessage'
#end

$CALLER_MODULE = "dell_powerconnect"

Puppet::Type.type(:powerconnect_config).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, config_type, force)
    #begin
      dev = Puppet::Util::NetworkDevice.current
      digestlocalfile=''
      digestserverconfig=''
      extBackupConfigfile = ''
      flashtmpfile = 'flash://backup-configtemp.scr'
      backedupPrevConfig = false
      yesflag = false
      txt = ''

      ##first check whether there is any backup-config, if so store it to flash and restore it at the end
      dev.transport.command('show backup-config') do |extBackup|
        extBackupConfigfile<< extBackup
      end
      if extBackupConfigfile.include? "Configuration script 'backup-config' not found"
        ##There is no existing backup config so do nothing
        Puppet.debug "no previous backup config found"
      else
        ##There is an existing backup config
        Puppet.debug "There is a previous backup config found"
        executeCommand(dev, 'copy backup-config ' + flashtmpfile,"Are you sure you want to start")   
        executeCommand(dev, 'delete backup-config',"Delete backup-config (Y/N)") 
        backedupPrevConfig = true
      end 

      ##copying the file from tftp to backup-config
      executeCommand(dev, 'copy ' + url + ' backup-config',"Are you sure you want to start")
      
      digestlocalfile = getfileMD5(dev, 'backup-config', 0..18)
      Puppet.debug "digest1 = #{digestlocalfile}"
      if digestlocalfile != 0 
        Puppet.debug "File transfer successful"
      else  
        Puppet.info "failed to copy the file from the server"
        #raise AsmException.new("ASM004", $CALLER_MODULE, nil, nil)
        raise "Failed to copy the configuration file from the server."
      end
            
      digestserverconfig = getfileMD5(dev, config_type+'-config', 0..19)
      Puppet.debug "digest2 = #{digestserverconfig}"

      if digestlocalfile != digestserverconfig || force == :true
        executeCommand(dev, 'copy '+ url +" "+ config_type+'-config',"Are you sure you want to start")
      end
      
      if digestlocalfile == digestserverconfig && force == :false
        Puppet.info("Switch is having the same configuration as that of url configured, so configuration copy is skipped.")
      end

      executeCommand(dev, 'delete backup-config',"Delete ")

      if backedupPrevConfig == true
        Puppet.debug "Restoring the previous backup config"
        #Restoring the backed up backed up backup config
        executeCommand(dev, 'copy ' + flashtmpfile+ ' backup-config',"Are you sure you want to start")
        # deleting the backup file from flash
        Puppet.debug "Deleting the backup file"
        executeCommand(dev, 'delete backup-configtemp.scr',"Delete ")
      end

      Puppet.debug "digest1 = #{digestlocalfile} && digest2 = #{digestserverconfig}"
      if config_type == 'startup' && (digestlocalfile != digestserverconfig || force == :true)
        Puppet.debug "Doing a reload"
        reloadswitch 
        Puppet.info("Going to sleep for 3 minutes, for switch reboot...")
        sleep 180
        Puppet.debug "i am here 10"
        initializeswitch      
      end
#    rescue AsmException => ae
#      ae.log_message
#    rescue Exception => e
#      AsmException.new("ASM001", $CALLER_MODULE, e).log_message
    #end
  end  
  
  def executeCommand(dev, cmd, str)
    yesflag = false
    dev.transport.command(cmd) do |out|
      out.each_line do |line|
        if line.include?(str) && yesflag == false
          if dev.transport.class.name.include?('Ssh')
            command = "y"
          else
            command = "y\r"
          end      
          dev.transport.send(command) 
          yesflag = true          
        end
      end   
    end 
  end  
  
  def getfileMD5(dev, configtype, slice)
    filecontent = ''
    dev.transport.command('show '+configtype) do |out|  
      Puppet.debug "I am here4" 
      filecontent<< out
      Puppet.debug "out = #{out}"
    end
    compareStr = "Configuration script "+"'"+configtype+"'"+" not found"
    if filecontent.include? compareStr
      digestlocalfile = 0
      return digestlocalfile
    end
  
    if dev.transport.class.name.include? 'Telnet'
      filecontent.slice!(slice)
    else
      if dev.transport.class.name.include? 'Ssh'
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
    dev = Puppet::Util::NetworkDevice.current
    yesflag = false
    doubleflag = false
    dev.transport.command('reload') do |out|
      out.each_line do |line|
        if line.start_with?("Are you sure you want to continue") && yesflag == false
          dev.transport.sendwithoutnewline("yy")
          yesflag = true
          doubleflag = true
        end
        if line.start_with?("Are you sure you want to reload the stack")
          if doubleflag == false
            break
          end
          return
        end
      end
      break
    end
    dev.transport.command('y') do |out|
      break
    end
  end
  
  def initializeswitch
    dev = Puppet::Util::NetworkDevice.current
    #Reesatblish transport session
    Puppet.info("Trying to reconnect to switch...")
    dev.connect_transport
    dev.switch.transport=dev.transport
    Puppet.info("Session established...")
  end
  
end