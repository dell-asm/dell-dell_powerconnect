#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/provider/powerconnect_interface/dell_powerconnect'

provider_class = Puppet::Type.type(:powerconnect_interface).provider(:dell_powerconnect)

describe provider_class do
  before do
    @interface = double('GigabitPort', :name => 'GigabitEthernet1/0/2',:params_to_hash => {})
    @interfaces = [ @interface ]

    @switch = double("switch", :vlan => @vlans,:params_to_hash => {})

    @transport = double("transport", :switch => @switch)
    Puppet::Provider::DellPowerconnect.stub(:transport).and_return(@transport)

    @resource = double("resource", :description   => 'ServerPort2',
    :mode => 'general',
    :add_vlans_in_general_mode   => '1-10',
    :add_vlans_in_trunk_mode   => '15-20',
    :remove_vlans_in_general_mode   => '12',
    :remove_vlans_in_trunk_mode   => '22,25',
    :shutdown   => false,
    :mtu => 9216 )

    @provider = provider_class.new(@resource)
  end


  describe "when looking up instances at prefetch" do
    before do
      @transport.stub(:command).and_yield(@transport)
    end

    it "should delegate to the interface fetcher" do
      @transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:params_to_hash)
      provider_class.get_current('GigabitEthernet1/0/2')
    end

    it "should return the given configuration data" do
      @transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:params_to_hash).and_return( :description   => 'ServerPort2',
      :mode => 'general',
      :add_vlans_in_general_mode   => '1-10',
      :add_vlans_in_trunk_mode   => '15-20',
      :remove_vlans_in_general_mode   => '12',
      :remove_vlans_in_trunk_mode   => '22,25',
      :shutdown   => false,
      :mtu => 9216 )
      provider_class.get_current('GigabitEthernet1/0/2').should == { :description   => 'ServerPort2',
        :mode => 'general',
        :add_vlans_in_general_mode   => '1-10',
        :add_vlans_in_trunk_mode   => '15-20',
        :remove_vlans_in_general_mode   => '12',
        :remove_vlans_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the configuration update method with current and past properties" do
      @instance = provider_class.new(:name => "GigabitEthernet1/0/2",  :description   => 'ServerPort2',
      :mode => 'general',
      :add_vlans_in_general_mode   => '1-10',
      :add_vlans_in_trunk_mode   => '15-20',
      :remove_vlans_in_general_mode   => '12',
      :remove_vlans_in_trunk_mode   => '22,25',
      :shutdown   => false,
      :mtu => 9216)
      @instance.transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:interface).with('GigabitEthernet1/0/2').and_return(@interface)
      @interface.should_receive(:update).with({:name => 'GigabitEthernet1/0/2',  :description   => 'ServerPort2',
        :mode => 'general',
        :add_vlans_in_general_mode   => '1-10',
        :add_vlans_in_trunk_mode   => '15-20',
        :remove_vlans_in_general_mode   => '12',
        :remove_vlans_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 },
      { :name => "GigabitEthernet1/0/2",  :description   => 'Server ISCI port',
        :mode => 'trunk',
        :add_vlans_in_general_mode   => '1-10',
        :add_vlans_in_trunk_mode   => '15-20',
        :remove_vlans_in_general_mode   => '12',
        :remove_vlans_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216 })

      @instance.description = "Server ISCI port"
      @instance.mode = "trunk"
      @instance.flush
    end
  end
end
