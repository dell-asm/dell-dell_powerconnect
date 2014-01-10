#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/provider/powerconnect_config/dell_powerconnect'
require 'fixtures/unit/puppet/provider/powerconnect_config/powerconnect_config_fixture'

describe Puppet::Type.type(:powerconnect_config).provider(:dell_powerconnect) do

  before(:each) do
      @fixture = Powerconnect_config_fixture_with_startupconfig.new
#      dummy_transport = double('transport')
#      dummy_transport.stub(:command).and_return ""
#      @fixture.provider.transport = dummy_transport
#      @fixture.provider.stub(:run)
    end

  context "when dell powerconnect config is created " do

    it "should have parent 'Puppet::Provider'" do
      described_class.new.should be_kind_of(Puppet::Provider)  
    end

    it "should have run method defined for applying the configuration" do
      described_class.instance_method(:run).should_not == nil
    end

    it "should have executecommand method defined for executing commands" do
      described_class.instance_method(:executeCommand).should_not == nil
    end

    it "should have getfileMD5 method defined for getting the file md5" do
      described_class.instance_method(:getfileMD5).should_not == nil
    end

    it "should have reload method defined for reloading the switch" do
      described_class.instance_method(:reloadswitch).should_not == nil
    end
  end
  
  context "when dell powerconnect config is being applied" do    

    it "should not restore backupconfig if there is no backupconfig in the switch, should call applyconfig if md5 are different and force is true
      , should call startupconfigpost update is config type is startup-config, force is true and and md5 are different" do
      @fixture.provider.should_receive(:preUpdateBackupConfigSave).once.with(@fixture.powerconnect_config[:url], 'flash://backup-configtemp.scr').and_return(false)
      @fixture.provider.should_receive(:getBackupConfigMD5).once.and_return("abcd1234")
      @fixture.provider.should_receive(:getSwitchConfigMD5).once.and_return("1234abcd")
      @fixture.provider.should_receive(:applyConfig).once.and_return("")
      @fixture.provider.should_receive(:cleanupBackupConfig)
      @fixture.provider.should_not_receive(:restoreOldBackupConfig)
      @fixture.provider.should_receive(:startupconfigPostUpdate)
      
      @fixture.provider.run(@fixture.powerconnect_config[:url], @fixture.powerconnect_config[:config_type], @fixture.powerconnect_config[:force])
    end 
    
    it "should not call applyconfig if md5 are same and force is false, should not call startupconfigpost update is config type is startup-config, 
    force is false and and md5 are same" do
      @fixture.provider.should_receive(:preUpdateBackupConfigSave).once.with(@fixture.powerconnect_config[:url],'flash://backup-configtemp.scr').and_return(true)
      @fixture.provider.should_receive(:getBackupConfigMD5).once.and_return("abcd1234")
      @fixture.provider.should_receive(:getSwitchConfigMD5).once.and_return("abcd1234")
      @fixture.provider.should_not_receive(:applyConfig)
      Puppet.should_receive(:info).once.with(Puppet::Provider::Powerconnect_messages::CONFIG_CONFIGS_MATCH_NO_FORCE)
      @fixture.provider.should_receive(:cleanupBackupConfig)
      @fixture.provider.should_receive(:restoreOldBackupConfig)
      @fixture.provider.should_not_receive(:startupconfigPostUpdate)
      #when
      @fixture.provider.run(@fixture.powerconnect_config[:url], @fixture.powerconnect_config[:config_type], :false)
    end  
    
    it "should mot call startupconfigPostUpdate if running-config is passed" do
      @fixture.provider.should_receive(:preUpdateBackupConfigSave).once.with(@fixture.powerconnect_config[:url],'flash://backup-configtemp.scr').and_return(true)
      @fixture.provider.should_receive(:getBackupConfigMD5).once.and_return("abcd1234")
      @fixture.provider.should_receive(:getSwitchConfigMD5).once.and_return("1234abcd")
      @fixture.provider.should_receive(:applyConfig)
      @fixture.provider.should_receive(:cleanupBackupConfig)
      @fixture.provider.should_receive(:restoreOldBackupConfig)
      @fixture.provider.should_not_receive(:startupconfigPostUpdate)
      #when
      @fixture.provider.run(@fixture.powerconnect_config[:url], "running-config", :false)
    end   
  end
end
