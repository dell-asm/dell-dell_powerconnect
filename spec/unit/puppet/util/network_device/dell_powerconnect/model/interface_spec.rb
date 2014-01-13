#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device'
require 'puppet/util/network_device/dell_powerconnect/model/interface'

describe Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Interface do
  before(:each) do
    @transport = double "transport"
    @interface = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Interface.new(@transport, {}, { :name => 'GigabitEthernet1/0/2' })
  end

  describe 'when managing interface configuration' do
    before do
      @interface_config = <<END
interface GigabitEthernet1/0/2
 description ServerPort2
 switchport mode general
 switchport general allowed vlans add 5-10 tagged
 channel-group 3 mode active
!
interface GigabitEthernet1/0/3
 description ServerPort3
 switchport mode trunk
 mtu 9216
 shutdown
!
interface GigabitEthernet1/0/4
 description ServerPort4
 mtu 9216
 channel-gorup 5 mode active
 siwtchport mode trunk
 switchport genaral allowed vlan add 5-10 tagged
 switchport genaral allowed general remove 5-10
 no shutdown
!
END
    end

    describe 'set and parse interface configuration params' do
      it 'should initialize various base params' do
        @interface.params.should_not == be_empty
      end

      it 'should set the name from the options' do
        @interface.name.should == 'GigabitEthernet1/0/2'
      end

      it 'should set the scope_name on the description param' do
        @interface.params[:description].scope_name.should == 'GigabitEthernet1/0/2'
      end

      it 'should parse the description param' do
        @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@interface_config)
        @interface.evaluate_new_params
        @interface.params[:description].value.should == 'ServerPort2'
      end
    end

    it 'should add the vlans to an interface' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/2')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/2", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('switchport general allowed vlan add 20 tagged')
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({:add_vlans_general_mode => '10-15'}, {:add_vlans_general_mode => '20'})
    end

    it 'should update the description' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/2')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/2", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('no description')
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({:description => 'ServerPort2'}, {:description => :absent})
    end

    it 'should remove the vlans from an interface' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/2')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/2", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('switchport general allowed vlan remove 20').once
      @transport.stub(:command).with('sh run', {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({:remove_vlans_general_mode => :absent }, {:remove_vlans_general_mode => 20})
    end

    it 'should add an interface to a port channel' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/2')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/2", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('channel-group 5 mode active')
      @transport.stub(:command).with("sh run", {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({}, {:add_interface_to_portchannel => '5'})
    end

    it 'should remove an interface from a port channel' do
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/2')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/2", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('no channel-group')
      @transport.stub(:command).with("sh run", {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({:remove_interface_from_portchannel => :absent}, {:remove_interface_from_portchannel => :true})
    end

    it 'should enable or disable the interface' do
      @interface = Puppet::Util::NetworkDevice::Dell_powerconnect::Model::Interface.new(@transport, {}, { :name => 'GigabitEthernet1/0/4' })
      @transport.should_receive(:command).with('conf t',  :prompt => /\(config\)#\s?\z/n).once
      @transport.should_receive(:command).with('end')
      @transport.should_receive(:command).with('interface GigabitEthernet1/0/4')
      @transport.should_receive(:command).with("interface GigabitEthernet1/0/4", anything)
      @transport.should_receive(:command).with('exit')
      @transport.should_receive(:command).with('shutdown')
      @transport.stub(:command).with("sh run", {:cache => true, :noop => false}).and_return(@interface_config)
      @interface.evaluate_new_params
      @interface.update({:shutdown => false}, {:shutdown => :true})
    end

  end
end
