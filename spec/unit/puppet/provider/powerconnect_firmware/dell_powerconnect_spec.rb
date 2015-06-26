#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:powerconnect_firmware).provider(:dell_powerconnect) do
  context "when powerconnect switch firmware is updated" do
    
    before(:each) do
      session = double('session').as_null_object
      session.stub(:command)
      transport = double('transport').as_null_object
      transport.stub(:session).and_return(session)
      @fixture = Puppet::Type.type(:powerconnect_firmware).new(
          :name               => 'image1',
          :imageurl           => 'tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk',
          :forceupdate        => 'true',
          :saveconfig         => 'true'
      )
      @fixture.provider.stub(:transport).and_return(transport)
    end

    it "should warn if skipping firmware update" do

      @fixture.provider.should_receive(:exists).once.and_return(true)
      Puppet.should_receive(:info).once.with(Puppet::Provider::Powerconnect_messages::FIRMWARE_VERSION_EXISTS_INFO).and_return("")
      @fixture.provider.should_not_receive(:update)
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_not_receive(:reboot_switch)

      @fixture.provider.run(@fixture[:imageurl],:false,:true)

    end

    it "should save the switch configuration if saveconfig flag set to :true" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_receive(:save_switch_config).once.and_return("")
      @fixture.provider.should_receive(:reboot_switch).once.and_return(true)
      @fixture.provider.should_receive(:ping_switch).once.and_return("")
      @fixture.provider.stub(:check_active_version).and_return(true)

      @fixture.provider.run(@fixture[:imageurl],:true,:true)

    end

    it "should not save the switch configuration if saveconfig flag set to false" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_receive(:reboot_switch).once.and_return(true)
      @fixture.provider.should_receive(:ping_switch).once.and_return("")
      @fixture.provider.stub(:check_active_version).and_return(true)

      @fixture.provider.run(@fixture[:imageurl],:true,:false)

    end

    it "should raise error if reboot failed" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_receive(:save_switch_config).once.and_return("")
      @fixture.provider.should_receive(:reboot_switch).once.and_return(false)
      @fixture.provider.should_not_receive(:ping_switch)

      expect {@fixture.provider.run(@fixture[:imageurl],:true,:true)}.to raise_error(Puppet::Error)

    end

    it "should raise error if image download fails" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:download_image).once.and_return("Failed")
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_not_receive(:reboot_switch)
      @fixture.provider.should_not_receive(:ping_switch)

      expect {@fixture.provider.run(@fixture[:imageurl],:true,:true)}.to raise_error(Puppet::Error)

    end

  end

end

