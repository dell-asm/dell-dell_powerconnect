#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device'
require 'puppet/util/network_device/dell_powerconnect/model/portchannel'
require 'pp'

describe Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel do
  before(:each) do
    @transport = double("transport")
    @portchannel = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel.new(@transport, {}, { :name => '45'})
  end

  describe 'when working with port channel params' do
    before do
      @portchannel_config = <<END
interface port-channel 45
switchport mode trunk
switchport trunk allowed vlan 1-30,32-4093
mtu 9216
exit
!
interface port-channel 46
mtu 9216
exit
!
END
    end

    it 'should initialize various base params' do
      @portchannel.params.should_not == be_empty
    end

    it 'should set the name from the options' do
      @portchannel.name.should == '45'
    end

    it 'should parse the allow vlans param' do
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@portchannel_config)
      @portchannel.evaluate_new_params
      @portchannel.params[:allowvlans].value.should == 'switchport trunk allowed vlan 1-30,32-4093'
    end

    it 'should add the allowed vlans to the port channel' do
      @portchannel = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel.new(@transport, {}, { :name => '45'})
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with("copy running-config startup-config").and_yield("Configuration Saved!")
      @transport.should_receive(:command).with('interface port-channel 45', anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('switchport mode trunk')
      @transport.should_receive(:command).with('switchport trunk allowed vlan add 20')
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@portchannel_config)
      @portchannel.evaluate_new_params
      @portchannel.update({:allowvlans => '31'}, {:allowvlans => '20'})
    end

    it 'should block the removed vlans to the port channel' do
      @portchannel = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Portchannel.new(@transport, {}, { :name => '45'})
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with("copy running-config startup-config").and_yield("Configuration Saved!")
      @transport.should_receive(:command).with('interface port-channel 45', anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('switchport mode trunk')
      @transport.should_receive(:command).with('switchport trunk allowed vlan remove 152')
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@portchannel_config)
      @portchannel.evaluate_new_params
      @portchannel.update({:removevlans => '141'}, {:removevlans => '152'})
    end
  end
end
