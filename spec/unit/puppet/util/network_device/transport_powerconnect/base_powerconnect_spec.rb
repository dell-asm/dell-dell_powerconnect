require 'spec_helper'
require 'puppet/util/network_device/transport_powerconnect/base_powerconnect'

describe Puppet::Util::NetworkDevice::Transport_powerconnect::Base_powerconnect do
  class TestTransport < Puppet::Util::NetworkDevice::Transport_powerconnect::Base_powerconnect
  end

  before(:each) do
    @fixture = TestTransport.new
  end

  describe "when sending commands" do
    it "should send the command to the telnet/ssh session" do
      @fixture.should_receive(:send).with("line", false)
      @fixture.command("line")
    end

    it "should expect an output matching the given prompt" do
      @fixture.should_receive(:expect).with(/prompt/)
      @fixture.command("line", :prompt => /prompt/)
    end

    it "should expect an output matching the default prompt" do
      @fixture.default_prompt = /defprompt/
      @fixture.should_receive(:expect).with(/defprompt/)
      @fixture.command("line")
    end

    it "should yield session output to the given block" do
      @fixture.should_receive(:expect).and_yield("output")
      @fixture.command("line") { |out| out.should == "output" }
    end

    it "should return session output to the caller" do
      @fixture.should_receive(:expect).and_return("output")
      @fixture.command("line").should == "output"
    end
  end
end
