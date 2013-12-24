require 'puppet/util/network_device'
require 'puppet/provider/dell_powerconnect'

Puppet::Type.type(:powerconnect_config).provide :dell_powerconnect, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, config_type)   
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    localfilecontent  =''
    digestlocalfile=''
    digestserverconfig=''
    switchconfigcontent = ''
    extBackupConfigfile = ''
    flashtmpfile = 'flash://backup-configtemp.bak'
    backedupPrevConfig = false
    
    ##first check whether there is any backup-config, if so store it to flash and restore it at the end
    dev.transport.command('show backup-config') do |extBackup|
      extBackupConfigfile<< extBackup
    end
    if extBackupConfigfile.include? "Configuration script 'backup-config' not found"
      ##There is no existing backup config so do nothing
      Puppet.debug "i am here 1"
    else
      Puppet.debug "i am here 2"
      ##There is an existing backup config
      dev.transport.command('copy backup-config ' + flashtmpfile) do |storebackup|
        storebackup.each_line do |line|
            if line.start_with?("Are you sure you want to start")
              dev.transport.send("y\r") 
            end
          end  
        backedupPrevConfig = true
        end
    end 
    
    ##copying the file from tftp to backup-config
    dev.transport.command('copy ' + url + ' backup-config') do |out|
      out.each_line do |line|
        if line.start_with?("Are you sure you want to start")
          dev.transport.send("y\r") 
        end
      end
      txt << out   
    end
    dev.transport.command('show backup-config') do |out1|
      localfilecontent<< out1
    end
    localfilecontent.slice!(0..18)
    Puppet.debug "client file = #{localfilecontent}"
    digestlocalfile = Digest::MD5.hexdigest(localfilecontent)
    Puppet.debug "digest1 = #{digestlocalfile}"
          
    if config_type == 'startup' 
      Puppet.debug "i am here 1"
      dev.transport.command('show startup-config') do |out2|
        switchconfigcontent<< out2
      end
      switchconfigcontent.slice!(0..19)
      Puppet.debug "switch config = #{switchconfigcontent}"
      digestserverconfig = Digest::MD5.hexdigest(switchconfigcontent)
      Puppet.debug "digest2 = #{digestserverconfig}"
    else
      dev.transport.command('show running-config') do |out2|
        switchconfigcontent<< out2
      end
      switchconfigcontent.slice!(0..19)
      digestserverconfig = Digest::MD5.hexdigest(switchconfigcontent)
      Puppet.debug "digest2 = #{digestserverconfig}"
    end
    return txt
  end  
end