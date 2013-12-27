require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_config).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, config_type, force)   
    dev = Puppet::Util::NetworkDevice.current
    digestlocalfile=''
    digestserverconfig=''
    extbackupconfigfile = ''
    flashtmpfile = 'flash://backup-configtemp.scr'
    backedupprevconfig = false
    
    ##first check whether there is any backup-config, if so store it to flash and restore it at the end
    dev.transport.command('show backup-config') do |extbackup|
      extbackupconfigfile<< extbackup
    end
    if extbackupconfigfile.include? "Configuration script 'backup-config' not found"
      ##There is no existing backup config so do nothing
      Puppet.debug "no previous backup config found"
    else
      ##There is an existing backup config
      Puppet.debug "There is a previous backup config found"
      executeCommand(dev, 'copy backup-config ' + flashtmpfile,"Are you sure you want to start")
    end 
    
    ##copying the file from tftp to backup-config
    executeCommand(dev, 'copy ' + url + ' backup-config',"Are you sure you want to start")
    
    digestlocalfile = getfileMD5(dev, 'show backup-config', 0..18)
    Puppet.debug "digest1 = #{digestlocalfile}"
          
    if config_type == 'startup'      
      digestserverconfig = getfileMD5(dev, 'show startup-config', 0..19)
      Puppet.debug "digest2 = #{digestserverconfig}"      
    else
      digestserverconfig = getfileMD5(dev, 'show running-config', 0..19)
      Puppet.debug "digest2 = #{digestserverconfig}"
    end
    
    if digestlocalfile == digestserverconfig && force == :false
      Puppet.info "No Configuration change"
    else 
      if config_type == 'startup'
        Puppet.debug "i am applying the startup config"
        executeCommand(dev, 'copy ' + url + ' startup-config',"Are you sure you want to start")
      else
        Puppet.debug "i am applying the running config"
        executeCommand(dev, 'copy ' + url + ' running-config',"Are you sure you want to start")
      end
    end    
    
    # Deleting the temporary backupconfig
    Puppet.debug "i am deleting the temporary backup config"
    executeCommand(dev, 'delete backup-config',"Delete ")
       
    if backedupprevconfig == true
      Puppet.debug "i am restoring the previous backup config"
      #Restoring the backed up backed up backup config
      executeCommand(dev, 'copy ' + flashtmpfile+ ' backup-config',"Are you sure you want to start")
      # deleting the backup file from flash
      Puppet.debug "i am deleting the backup file"
      executeCommand(dev, 'delete backup-configtemp.scr',"Delete ")
    end
    
    if config_type == 'startup' && force == :true
      Puppet.debug "i am doing a reload"
      #executeCommand(dev, 'reload', "Are you sure you want to")
      dev.transport.command('reload') do |out|
        out.each_line do |line|
          Puppet.debug "line = #{line}"
          if line.include?("Are you sure you want to")
            Puppet.debug "match found"
            dev.transport.send("y\r")
            return
          end
        end
      end  
    end
  end  
  
  def executeCommand(dev, cmd, str)
    dev.transport.command(cmd) do |out|
      out.each_line do |line|
        Puppet.debug "line = #{line}"
        if line.include?(str)
          Puppet.debug "match found"
          dev.transport.send("y\r") 
        end
      end   
    end  
  end
  
  def getfileMD5(dev, cmd, slice)
    filecontent = ''
    dev.transport.command(cmd) do |out|
      filecontent<< out
    end
    filecontent.slice!(slice)
    digestlocalfile = Digest::MD5.hexdigest(filecontent)
    return digestlocalfile
  end
end