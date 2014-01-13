#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/provider/powerconnect_interface/dell_powerconnect'

provider_class = Puppet::Type.type(:powerconnect_interface).provider(:dell_powerconnect)

describe provider_class do
  before do
    @interface = double('GigabitPort', :name => 'GigabitEthernet1/0/2',:params_to_hash => {})
    @interfaces = [ @interface ]

    @switch = double("switch", :vlan => @vlans,:params_to_hash => {})

    @device = double("device", :switch => @switch)

    @resource = double("resource", :description   => 'ServerPort2',
    :mode => 'general',
    :add_valns_in_general_mode   => '1-10',
    :add_valns_in_trunk_mode   => '15-20',
    :remove_valns_in_general_mode   => '12',
    :remove_valns_in_trunk_mode   => '22,25',
    :shutdown   => false,
    :mtu => 9216 )

    @provider = provider_class.new(@device, @resource)
  end

  it "should have a parent of Puppet::Provider::Dell_powerconnect" do
    provider_class.should < Puppet::Provider::Dell_powerconnect
  end

  it "should have an instances method" do
    provider_class.should respond_to(:instances)
  end

  describe "when looking up instances at prefetch" do
    before do
      @device.stub(:command).and_yield(@device)
    end

    it "should delegate to the device interface fetcher" do
      @device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:params_to_hash)
      provider_class.lookup(@device, 'GigabitEthernet1/0/2')
    end

    it "should return the given configuration data" do
      @device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:params_to_hash).and_return( :description   => 'ServerPort2',
      :mode => 'general',
      :add_valns_in_general_mode   => '1-10',
      :add_valns_in_trunk_mode   => '15-20',
      :remove_valns_in_general_mode   => '12',
      :remove_valns_in_trunk_mode   => '22,25',
      :shutdown   => false,
      :mtu => 9216 )
      provider_class.lookup(@device, 'GigabitEthernet1/0/2').should == { :description   => 'ServerPort2',
        :mode => 'general',
        :add_valns_in_general_mode   => '1-10',
        :add_valns_in_trunk_mode   => '15-20',
        :remove_valns_in_general_mode   => '12',
        :remove_valns_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :name => "GigabitEthernet1/0/2",  :description   => 'ServerPort2',
      :mode => 'general',
      :add_valns_in_general_mode   => '1-10',
      :add_valns_in_trunk_mode   => '15-20',
      :remove_valns_in_general_mode   => '12',
      :remove_valns_in_trunk_mode   => '22,25',
      :shutdown   => false,
      :mtu => 9216)
      @instance.device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:update).with({:name => 'GigabitEthernet1/0/2',  :description   => 'ServerPort2',
        :mode => 'general',
        :add_valns_in_general_mode   => '1-10',
        :add_valns_in_trunk_mode   => '15-20',
        :remove_valns_in_general_mode   => '12',
        :remove_valns_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 },
      { :name => "GigabitEthernet1/0/2",  :description   => 'Server ISCI port',
        :mode => 'trunk',
        :add_valns_in_general_mode   => '1-10',
        :add_valns_in_trunk_mode   => '15-20',
        :remove_valns_in_general_mode   => '12',
        :remove_valns_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 })

      @instance.description = "Server ISCI port"
      @instance.mode = "trunk"
      @instance.flush
    end
  end
end
