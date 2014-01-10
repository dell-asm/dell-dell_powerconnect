#! /usr/bin/env ruby

require 'spec_helper'
require 'fixtures/unit/puppet/provider/powerconnect_firmware/Powerconnect_firmware_fixture'

describe Puppet::Type.type(:powerconnect_firmware).provider(:dell_powerconnect) do

  context "when powerconnect firmware provider is created " do

    it "should have parent 'Puppet::Provider'" do
      described_class.new.should be_kind_of(Puppet::Provider)
    end

    it "should have update method defined for updating firmware" do
      described_class.instance_method(:update).should_not == nil
    end

    it "should have download_image method defined for downloading firmware image on switch" do
      described_class.instance_method(:download_image).should_not == nil
    end

    it "should have reboot_switch method defined for rebooting powerconnect switch" do
      described_class.instance_method(:reboot_switch).should_not == nil
    end

    it "should have exists method defined for checking if firmware already exists on switch" do
      described_class.instance_method(:exists).should_not == nil
    end

    it "should have save_switch_config method defined for saving running configuration" do
      described_class.instance_method(:save_switch_config).should_not == nil
    end

  end

  context "when powerconnect switch firmware is updated" do
    
    before(:each) do
      @fixture = Powerconnect_firmware_fixture.new
    end

    it "should warn if skipping firmware update" do

      @fixture.provider.should_receive(:exists).once.and_return(true)
      Puppet.should_receive(:info).once.with(Puppet::Provider::Powerconnect_messages::FIRMWARE_VERSION_EXISTS_INFO).and_return("")
      @fixture.provider.should_not_receive(:update)
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_not_receive(:reboot_switch)

      @fixture.provider.run(@fixture.get_image_url,false,true)

    end

    it "should save the switch configuration if saveconfig flag set to true" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_receive(:save_switch_config).once.and_return("")
      @fixture.provider.should_receive(:reboot_switch).once.and_return(true)
      @fixture.provider.should_receive(:ping_switch).once.and_return("")

      @fixture.provider.run(@fixture.get_image_url,true,true)

    end

    it "should not save the switch configuration if saveconfig flag set to false" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_receive(:reboot_switch).once.and_return(true)
      @fixture.provider.should_receive(:ping_switch).once.and_return("")

      @fixture.provider.run(@fixture.get_image_url,true,false)

    end

    it "should raise error if reboot failed" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:update).once.and_return("")
      @fixture.provider.should_receive(:save_switch_config).once.and_return("")
      @fixture.provider.should_receive(:reboot_switch).once.and_return(false)
      @fixture.provider.should_not_receive(:ping_switch)

      expect {@fixture.provider.run(@fixture.get_image_url,true,true)}.to raise_error(Puppet::Error)

    end

    it "should raise error if image download fails" do

      @fixture.provider.should_receive(:exists).once.and_return(false)
      @fixture.provider.should_receive(:download_image).once.and_return("Failed")
      @fixture.provider.should_not_receive(:save_switch_config)
      @fixture.provider.should_not_receive(:reboot_switch)
      @fixture.provider.should_not_receive(:ping_switch)

      expect {@fixture.provider.run(@fixture.get_image_url,true,true)}.to raise_error(Puppet::Error)

    end

  end

end

