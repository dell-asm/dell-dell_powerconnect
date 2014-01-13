#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device/dell_powerconnect/device'

describe Puppet::Util::NetworkDevice::Dell_powerconnect::Device do
  before(:each) do
    @transport = double('transport', :is_a? => true, :command => '',:user => 'user',:password => 'password')
    @dell = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new('ssh://user:password@localhost:22/')
    @dell.transport = @transport
  end

  describe 'when creating the device' do
    it 'should find the enable password from the url' do
      dell = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new('ssh://user:password@localhost:22/?enable=enable_password')
      dell.enable_password == 'enable_password'
    end

    it 'should prefer the enable password from the options' do
      dell = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new('ssh://user:password@localhost:22/?enable=enable_password', :enable_password => 'mypass')
      dell.enable_password == 'mypass'
    end

    it 'should find the crypt bool from the url' do
      File.stub(:read).with('/etc/puppet/networkdevice-secret').and_return('foobar')
      dell = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new('ssh://96cc073a43df48098b6b4cae9366c677:7d211471517adf2821bd88ced8e8d378@localhost:22/?enable=enable_password&crypt=true')
      dell.crypt == true
    end

    it 'should decrypt the provided user and password' do
      Puppet.stub(:[]).with(:confdir).and_return('/etc/puppet')
      File.stub(:read).with('/etc/puppet/networkdevice-secret').and_return('foobar')
      dell = Puppet::Util::NetworkDevice::Dell_powerconnect::Device.new('ssh://96cc073a43df48098b6b4cae9366c677:7d211471517adf2821bd88ced8e8d378@localhost:22/?enable=enable_password&crypt=true')
      dell.transport.user.should == 'user'
      dell.transport.password.should == 'pass'
    end

  end

  describe "when connecting to the physical device" do
    it "should connect to the transport" do
      @transport.should_receive(:connect)
      @dell.should_receive(:login)
      @dell.should_receive(:enable)
      @transport.should_receive(:command).with("terminal length 0", :noop => false)
      @dell.connect_transport
    end

    #    it "should create the switch object" do
    #      Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Switch.should_receive(:new).with(@transport, {}).and_return(double('switch'))
    #      # TODO: Convert it to Method calls
    #      # Dont't access IVars directly
    #      @facts = double('facts')
    #      @facts.stub(:facts_to_hash).and_return({})
    #      @dell.instance_variable_set(:@facts, @facts)
    #      @dell.init_switch
    #    end

    describe "when login in" do
      it "should not login if transport handles login" do
        @transport.should_receive(:handles_login?).and_return(true)
        @transport.should_not_receive(:command)
        @transport.should_not_receive(:expect)
        @dell.login
      end

      it "should send username if one has been provided" do
        @transport.should_receive(:handles_login?).and_return(false)
        @transport.should_receive(:command).with("user", {:prompt => /^Password:/, :noop => false})
        @dell.login
      end

      it "should send password after the username" do
        @transport.should_receive(:handles_login?).and_return(false)
        @transport.should_receive(:command).with("user", {:prompt => /^Password:/, :noop => false})
        @transport.should_receive(:command).with("password", :noop => false)
        @dell.login
      end

      #it "should expect the Password: prompt if no user was sent" do
      #@transport.user = ''
      #@transport.expects(:expect).with(/^Password:/)
      #@transport.expects(:command).with("password", :noop => false)
      #@dell.login
      #end

    end

    describe "when entering enable password" do
      it "should raise an error if no enable password has been set" do
        @dell.enable_password = nil
        expect{ @dell.enable }.to raise_error
      end

      it "should send the enable command and expect an enable prompt" do
        @dell.enable_password = 'mypass'
        @transport.should_receive(:command).with("enable", {:noop => false})
        @dell.enable
      end

      it "should send the enable password" do
        @dell.enable_password = 'mypass'
        @transport.should_receive(:command).with("enable", {:noop => false}).and_yield("Password:")
        @transport.should_receive(:send).with("mypass\r")
        @dell.enable
      end
    end

  end
end
