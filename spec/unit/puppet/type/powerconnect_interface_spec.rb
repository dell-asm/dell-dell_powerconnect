#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:powerconnect_interface) do

  let(:title) { 'powerconnect_interface' }

  let(:name) { 'GigabitEthernet1/0/2' }

  context 'should compile with given test params' do
    let(:params) { {
        :description   => 'ServerPort2',
        :mode => 'general',
        :add_valns_in_general_mode   => '1-10',
        :add_valns_in_trunk_mode   => '15-20',
        :remove_valns_in_general_mode   => '12',
        :remove_valns_in_trunk_mode   => '22,25',
        :shutdown   => false,
        :mtu => 9216,
      }}
    it do
      expect {
        should compile
      }
    end

  end

  describe "when validating attribute values" do

    it "should have a 'name' parameter'" do
      described_class.new(:name => name)[:name].should == name
    end

    [:name].each do |p|
      it "should have a #{p} param" do
        described_class.attrtype(p).should == :param
      end
    end

    [:description, :mode, :add_vlans_trunk_mode,
      :remove_vlans_trunk_mode, :add_vlans_general_mode,
      :remove_vlans_general_mode, :add_interface_to_portchannel,
      :remove_interface_from_portchannel, :shutdown, :mtu
    ].each do |p|
      it "should have a #{p} property" do
        described_class.attrtype(p).should == :property
      end
    end

    describe "name" do
      it "should allow name starting with Gigabitethernet or Gi or Tengigabitethernet or Te followed by unit/slot/port." do
        described_class.new(:name => 'GigabitEthernet1/0/21')
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => "SomeOtherName") }.to raise_error Puppet::Error, /SomeOtherName is not a valid interface name. Valid interface name should start with 'Gigabitethernet or Gi or Tengigabitethernet or Te' followed by unit\/slot\/port./
      end
    end

    describe 'VLAN memebership mode of an interface' do
      [ :access, :general, :trunk ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name =>name, :mode => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:mode => "somethingelse") }.to raise_error
      end
    end

    describe "add valns to an intreface" do
      [ ["1", "a single vlan"],
        ["10", "a single vlan"],
        ["10-20", "a single vlan range"],
        ["1,5", "a list of non consecutive vlans"],
        ["1,5,10", "a list of non consecutive vlans"],
        ["1,5,10,20,30,40,50,1000", "a list of non consecutive vlans"],
        ["1-10,12,15", "a list of non consecutive vlans and ranges"],
        ["1,10-12,15", "a list of non consecutive vlans and ranges"],
        ["1,10,12-15", "a list of non consecutive vlans and ranges"],
      ].each do |value, desc|
        it "should allow setting allowed vlans to #{desc}: #{value.inspect}" do
          described_class.new(:name => name, :add_vlans_trunk_mode => value, :add_vlans_general_mode => value)
        end
      end

      [ "VLAN1", "1-", "1,-", "-", "," ].each do |value|
        it "should not allow vlan values to be #{value.inspect}" do
          expect { described_class.new(:name => name, :add_vlans_trunk_mode => value, :add_vlans_general_mode => value) }.to raise_error
        end
      end
    end

    describe "remove valns from an intreface" do
      [ ["1", "a single vlan"],
        ["10", "a single vlan"],
        ["10-20", "a single vlan range"],
        ["1,5", "a list of non consecutive vlans"],
        ["1,5,10", "a list of non consecutive vlans"],
        ["1,5,10,20,30,40,50,1000", "a list of non consecutive vlans"],
        ["1-10,12,15", "a list of non consecutive vlans and ranges"],
        ["1,10-12,15", "a list of non consecutive vlans and ranges"],
        ["1,10,12-15", "a list of non consecutive vlans and ranges"],
      ].each do |value, desc|
        it "should allow setting removed vlans to #{desc}: #{value.inspect}" do
          described_class.new(:name => name, :remove_vlans_trunk_mode => value, :remove_vlans_general_mode => value)
        end
      end

      [ "VLAN1", "1-", "1,-", "-", "," ].each do |value|
        it "should not allow vlan values to be #{value.inspect}" do
          expect { described_class.new(:name => name, :remove_vlans_trunk_mode => value, :remove_vlans_general_mode => value) }.to raise_error
        end
      end
    end

    describe "add interface to a portchannel" do
      it "should add to a portchannel between 1 and 128" do
        described_class.new(:name => name, :add_interface_to_portchannel=> '122')
      end
      it "should raise an exception on everything else" do
        expect { described_class.new(:name => name, :add_interface_to_portchannel => '130') }.to raise_error
      end
    end

    describe "remove interface from a portchannel" do
      it "should remove this portchannel form the interface" do
        described_class.new(:name => name, :remove_interface_from_portchannel=> :true)
      end
      it "should not remove this portchannel form the interface" do
        described_class.new(:name => name, :remove_interface_from_portchannel => :false)
      end
    end

    describe "mtu " do
      it "should allow mtu value between 1518 and 9216" do
        described_class.new(:name => name, :mtu => '9216')[:mtu].should == '9216'
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => name, :mtu => 'mtu') }.to raise_error
        expect { described_class.new(:name => name, :mtu => '9300') }.to raise_error
      end
    end

    describe 'enable or disable  interface' do
      [ :true, :false ].each do |val|
        it "should allow the value #{val.inspect} to enable or disable the interface" do
          described_class.new(:name =>name, :shutdown => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => name, :shutdown => 'somethingelse') }.to raise_error
      end
    end

  end
end