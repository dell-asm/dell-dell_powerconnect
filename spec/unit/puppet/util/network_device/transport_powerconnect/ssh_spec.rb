#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device/transport_powerconnect/ssh'

describe Puppet::Util::NetworkDevice::Transport_powerconnect::Ssh, :if => Puppet.features.ssh? do

  before(:each) do
    @fixture = Puppet::Util::NetworkDevice::Transport_powerconnect::Ssh.new()
    @fixture.host = "localhost"
    @fixture.port = 22
    @fixture.user = "user"
    @fixture.password = "pass"
  end

  it "should handle login through the transport" do
    @fixture.should be_handles_login
  end

  #  it "should connect to the given host and port" do
  #    Net::SSH.should_receive(:start).with(|host, user, args| user == "user" && args[:password] == "pass" ).and_return("")
  #    @fixture.connect
  #  end
  #
  #  it "should connect using the given username and password" do
  #    Net::SSH.expects(:start).with { |host, user, args| user == "user" && args[:password] == "pass" }.returns stub_everything
  #    @fixture.user = "user"
  #    @fixture.password = "pass"
  #
  #    @fixture.connect
  #  end

  it "should raise a Puppet::Error when encountering an authentication failure" do
    Net::SSH.should_receive(:start).and_raise(Net::SSH::AuthenticationFailed)
    @fixture.host = "localhost"
    @fixture.user = "user"

    expect { @fixture.connect }.to raise_error(Puppet::Error)
  end

  describe "when connected" do
    before(:each) do
      @ssh = double('ssh')
      @channel = double('channel')
      Net::SSH.stub(:start).and_return(@ssh)
      @ssh.stub(:loop)
      @fixture.stub(:expect)
    end

    it "should open a channel" do
      @ssh.should_receive(:open_channel).and_return(@channel)
      @fixture.connect
    end

    it "should request a pty" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).and_return("")
      @fixture.connect
    end

    it "should create a shell channel" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell")
      @fixture.connect
    end

    it "should raise an error if shell channel creation fails" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, false)
      expect { @fixture.connect }.to raise_error(RuntimeError)
    end

    it "should register an on_data ,on_extended_data and on_close callback" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.should_receive(:on_data)
      @channel.should_receive(:on_extended_data)
      @channel.should_receive(:on_close)
      @fixture.connect
    end

    it "should accumulate data to the buffer on data" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.should_receive(:on_data).and_yield(@channel, "data")
      @channel.should_receive(:on_extended_data)
      @channel.should_receive(:on_close)
      @fixture.connect
      @fixture.buf.should == "data"
    end

    it "should accumulate data to the buffer on extended data" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.should_receive(:on_data)
      @channel.should_receive(:on_extended_data).and_yield(@channel, 1, "data")
      @channel.should_receive(:on_close)
      @fixture.connect
      @fixture.buf.should == "data"
    end

    #    it "should mark eof on close" do
    #      @ssh.should_receive(:open_channel).and_yield(@channel)
    #      @channel.should_receive(:request_pty).and_return("")
    #      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, true)
    #      @channel.should_receive(:on_data)
    #      @channel.should_receive(:on_extended_data)
    #      @channel.should_receive(:on_close).and_return(@channel)
    #      @fixture.connect
    #      @fixture.should be_eof
    #    end

    it "should expect output to conform to the default prompt" do
      @ssh.should_receive(:open_channel).and_yield(@channel)
      @channel.should_receive(:request_pty).and_return("")
      @channel.should_receive(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.should_receive(:on_data)
      @channel.should_receive(:on_extended_data)
      @channel.should_receive(:on_close)
      @fixture.should_receive(:default_prompt).and_return("prompt")
      @fixture.should_receive(:expect).with("prompt")
      @fixture.connect
    end

    it "should start the ssh loop" do
      @ssh.should_receive(:open_channel).and_return(@channel)
      @ssh.should_receive(:loop)
      @fixture.connect
    end
  end

  describe "when closing" do
    before(:each) do
      @ssh = double('ssh')
      @channel = double('channel')
      Net::SSH.stub(:start).and_return(@ssh)
      @ssh.stub(:open_channel).and_yield(@channel)
      @channel.stub(:request_pty).and_return("")
      @channel.stub(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.stub(:on_data)
      @channel.stub(:on_extended_data)
      @channel.stub(:on_close)
      @fixture.stub(:expect)
      @fixture.connect
    end

    it "should close the channel" do
      @channel.should_receive(:close)
      @ssh.stub(:close)
      @fixture.close
    end

    it "should close the ssh session" do
      @channel.stub(:close)
      @ssh.should_receive(:close)
      @fixture.close
    end
  end

  describe "when sending commands" do
    before(:each) do
      @ssh = double('ssh')
      @channel = double('channel')
      Net::SSH.stub(:start).and_return(@ssh)
      @ssh.stub(:open_channel).and_yield(@channel)
      @channel.stub(:request_pty).and_return("")
      @channel.stub(:send_channel_request).with("shell").and_yield(@channel, true)
      @channel.stub(:on_data)
      @channel.stub(:on_extended_data)
      @channel.stub(:on_close)
      @fixture.stub(:expect)
      @fixture.connect
    end

    it "should send data to the ssh channel" do
      @channel.should_receive(:send_data).with("data\n")
      @fixture.command("data")
    end

    it "should expect the default prompt afterward" do
      @channel.should_receive(:send_data)
      @fixture.should_receive(:default_prompt).and_return("prompt")
      @fixture.should_receive(:expect).with("prompt")
      @fixture.command("data")
    end

    it "should expect the given prompt" do
      @channel.should_receive(:send_data)
      @fixture.should_receive(:expect).with("myprompt")
      @fixture.command("data", :prompt => "myprompt")
    end

    it "should yield the buffer output to given block" do
      @channel.should_receive(:send_data)
      @fixture.should_receive(:expect).and_yield("output")
      @fixture.command("data") do |out|
        out.should == "output"
      end
    end

    it "should return buffer output" do
      @channel.should_receive(:send_data)
      @fixture.should_receive(:expect).and_return("output")
      @fixture.command("data").should == "output"
    end
  end

  describe "when expecting output" do
    before(:each) do
      @connection = double('connection')
      @socket = double('socket')
      transport = double('transport', :socket => @socket)
      @ssh = double('ssh', :transport => transport)
      @channel = double('channel', :connection => @connection)
      @socket.stub('closed?')
      @fixture.ssh = @ssh
      @fixture.channel = @channel
    end

    it "should process the ssh event loop" do
      IO.stub(:select)
      @fixture.buf = "output"
      @fixture.should_receive(:process_ssh)
      @fixture.expect(/output/)
    end

    it "should return the output" do
      IO.stub(:select)
      @fixture.buf = "output"
      @fixture.stub(:process_ssh)
      @fixture.expect(/output/).should == "output"
    end

    describe "when processing the ssh loop" do
      it "should advance one tick in the ssh event loop and exit on eof" do
        @fixture.buf = ''
        @connection.should_receive(:process).and_raise(EOFError)
        @fixture.process_ssh
      end
    end
  end
end
