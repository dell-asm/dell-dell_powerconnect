#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:powerconnect_firmware) do

  let :resource do
    described_class.new(
    :name          		  => 'image1',
	  :imageurl			      => 'tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk',
	  :forceupdate				=> 'true',
	  :saveconfig				  => 'true'
	)
  end

  it "should have a 'name' parameter'" do
    described_class.new(:name => 'image1')[:name].should == 'image1'
  end

#  it "should be applied on device" do
#    described_class.new(:name => resource.name).must be_appliable_to_device
#  end
  
  describe "when validating attributes" do
    [ :name, :imageurl, :forceupdate, :saveconfig ].each do |param|
      it "should have a #{param} param" do
        described_class.attrtype(param).should == :param
      end
    end
  
    [ :returns ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating attribute values" do
    before do
      @provider = stub 'provider', :class => described_class.defaultprovider, :clear => nil
      described_class.defaultprovider.stubs(:new).returns(@provider)
    end

    describe "for name" do
      it "should allow a valid TFTP name" do
        resource.name.should eq( 'image1')
      end      
    end

    describe "for imageurl" do
      it "should allow a valid string for tftp url" do
        described_class.new(:name => resource.name, :imageurl => 'tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk')[:imageurl].should == 'tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk'
      end
    end

    describe 'for forceupdate' do
      [ :true, :false ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :forceupdate => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :forceupdate => :foobar) }.to raise_error
      end
    end
    
    describe 'for saveconfig' do
      [ :true, :false ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :saveconfig => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :saveconfig => :foobar) }.to raise_error
      end
    end

  end
  
end