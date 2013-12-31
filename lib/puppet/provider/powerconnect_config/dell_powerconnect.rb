require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_config).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, config_type, force)   
    dev = Puppet::Util::NetworkDevice.current
    digestlocalfile=''
    digestserverconfig=''
    extBackupConfigfile = ''
    flashtmpfile = 'flash://backup-configtemp.scr'
    backedupPrevConfig = false
        
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
    end 
    
    ##copying the file from tftp to backup-config
    executeCommand(dev, 'copy ' + url + 'backup-config',"Are you sure you want to start")
    
    digestlocalfile = getfileMD5(dev, 'backup-config', 0..18)
    Puppet.debug "digest1 = #{digestlocalfile}"
          
    if config_type == 'startup'      
      digestserverconfig = getfileMD5(dev, 'startup-config', 0..19)
      Puppet.debug "digest2 = #{digestserverconfig}"      
    else
      digestserverconfig = getfileMD5(dev, 'running-config', 0..19)
      Puppet.debug "digest2 = #{digestserverconfig}"
    end
    
    if digestlocalfile == digestserverconfig && force == :false
      Puppet.info "No Configuration change"
    else 
      if config_type == 'startup'
        Puppet.debug "Applying the startup config"
        executeCommand(dev, 'copy ' + url + ' startup-config',"Are you sure you want to start")
      else
        Puppet.debug "Applying the running config"
        executeCommand(dev, 'copy ' + url + ' running-config',"Are you sure you want to start")
      end
    end
       
    if backedupPrevConfig == true
      Puppet.debug "Restoring the previous backup config"
      #Restoring the backed up backed up backup config
      executeCommand(dev, 'copy ' + flashtmpfile+ ' backup-config',"Are you sure you want to start")
      # deleting the backup file from flash
      Puppet.debug "Deleting the backup file"
      executeCommand(dev, 'delete backup-configtemp.scr',"Delete ")
    end
    
    if config_type == 'startup' && force == :true
      Puppet.debug "Doing a reload"
      #executeCommand(dev, 'reload', "Are you sure you want to") 
      rebootswitch  
    end
  end  
  
  def executeCommand(dev, cmd, str)
    dev.transport.command(cmd) do |out|
      out.each_line do |line|
        if line.include?(str)
          dev.transport.send("y\r") 
          if dev.transport.class.name.include? 'Ssh'
            return
          end          
        end
      end   
    end  
  end
  
  def getfileMD5(dev, configtype, slice)
    filecontent = ''
    dev.transport.command('show '+configtype) do |out|   
      filecontent<< out
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
      else
      end
    end
    digestlocalfile = Digest::MD5.hexdigest(filecontent)
    return digestlocalfile
  end
  
  def rebootswitch()
    dev = Puppet::Util::NetworkDevice.current
    flagfirstresponse=false
    flagsecondresponse=false
    flagthirdresponse=false

    dev.transport.command("reload")  do |out|
      firstresponse =out.scan("Are you sure you want to continue")
      secondresponse = out.scan("Are you sure you want to reload the stack")
      unless firstresponse.empty?
        flagfirstresponse=true
        break
      end
      unless secondresponse.empty?
        flagsecondresponse=true
        break
      end
    end

    #Some times sending reload command returning with console prompt without doing anything, in that case retry max for 3 times
#    if (!flagfirstresponse && !flagsecondresponse) && rebootrycount<3
#      Puppet.debug "i am here 1"
#      rebootrycount=rebootrycount+1
#      rebootswitch()
#    end

    if flagfirstresponse
      dev.transport.command("y") do |out|
        thirdresponse = out.scan("Are you sure you want to reload the stack")
        unless thirdresponse.empty?
          flagthirdresponse=true
          break
        end
      end
      if flagthirdresponse
        dev.transport.send("y\r") do |out|
        end
      else
        Puppet.debug "ELSE BLOCK1.2"
      end
    else
      Puppet.debug "ELSE BLOCK1.1"
    end
    if flagsecondresponse
      dev.transport.send("y\r") do |out|
        #without this block expecting for prompt and so hanging
        break
      end
    else
      Puppet.debug "ELSE BLOCK2"
    end

    #Sleep for 3 mins t wait for switch to come up
    Puppet.info("Going to sleep for 3 minutes, for switch reboot...")
    sleep 180

    #Reesatblish transport session
    Puppet.info("Trying to reconnect to switch...")
    dev.connect_transport
    dev.switch.transport=dev.transport
    Puppet.info("Session established...")
  end
end