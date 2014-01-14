#! /usr/bin/env ruby
require 'spec_helper'
require 'ap'
require 'puppet/util/network_device'
require 'puppet/util/network_device/dell_powerconnect/model/vlan'

describe Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan do
  before :each do
    @transport = double("transport")
    @vlan = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan.new(@transport, {}, { :name => '5', :ensure => :present })
  end

  describe 'when working with vlan params' do
    before do
      @vlan_config = <<END
VLAN   Name                             Ports          Type
-----  ---------------                  -------------  --------------
1      default                          Po1-128,       Default
                                        Gi1/0/1-19,
                                        Gi1/0/21-24,
                                        Te1/1/1-2
5      VLAN005                          Po23,Po45      Static
32     32more                           Po23,Po45,     Static
                                        Gi1/0/21
33     myvlan32gaingaingain             Po23           Static
34     demo-vlan-34                     Po23,Po45      Static
51     VLAN0051                         Po23,Po45      Static
152    VLAN0152                         Po23,Po45,     Static
                                        Gi1/0/22,
                                        Te1/1/1
162    VLAN0162                         Po23,Po45,     Static
                                        Gi1/0/22

END
    end

    it 'should initialize various base params' do
      @vlan.params.should_not == be_empty
    end

    it 'should set the name from the options' do
      @vlan.name.should == '5'
    end

    it 'should set the scope_name on the vlan_name param' do
      @vlan.params[:vlan_name].scope_name.should == '5'
    end

    it 'should parse description of the vlan_name param' do
      @transport.stub(:command).with('show vlan', {:cache => true, :noop => false}).and_return(@vlan_config)
      @vlan.evaluate_new_params
      @vlan.params[:vlan_name].value.should == "VLAN005"
    end

    it 'should add a vlan with default description' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with("copy running-config startup-config").and_yield("Configuration Saved!")
      @transport.should_receive(:command).with('vlan 50', :prompt => /\(config-vlan50\)#\s?\z/n)
      @transport.should_receive(:command).with('exit')
      @transport.stub(:command).with('show vlan', {:cache => true, :noop => false}).and_return(@vlan_config)
      @vlan = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Vlan.new(@transport, {}, { :name => '50', :ensure => :present })
      @vlan.evaluate_new_params
      @vlan.update({:ensure => :absent}, {:ensure => :present})

    end

    it 'should update a vlan description' do
      @transport.should_receive(:command).with('conf t', :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with("copy running-config startup-config").and_yield("Configuration Saved!")
      @transport.should_receive(:command).with('vlan 5', :prompt => /\(config-vlan5\)#\s?\z/n)
      @transport.should_receive(:command).with("name \"VLAN005changed\"")
      @transport.should_receive(:command).with('exit')
      @transport.stub(:command).with("show vlan", {:cache => true, :noop => false}).and_return(@vlan_config)
      @vlan.evaluate_new_params
      @vlan.update({:ensure => :present, :vlan_name => 'VLAN005'}, {:ensure => :present, :vlan_name => 'VLAN005changed'})
    end

    it 'should remove a vlan' do
      @transport.should_receive(:command).with('conf t', :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with("copy running-config startup-config").and_yield("Configuration Saved!")
      @transport.should_receive(:command).with("no vlan 5")
      @transport.stub(:command).with("show vlan", {:cache => true, :noop => false}).and_return(@vlan_config)
      @vlan.evaluate_new_params
      @vlan.update({:ensure => :present}, {:ensure => :absent})
    end
  end
end