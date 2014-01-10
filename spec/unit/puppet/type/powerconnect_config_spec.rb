#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:powerconnect_config) do

  let :resource do
    described_class.new(
    :name           => 'config1',
    :url            => 'tftp://10.10.10.10/startup.scr',
    :config_type    => 'startup',
    :force          => true
    )
  end

  it "should have a 'name' parameter'" do
    described_class.new(:name => "config1")[:name].should == "config1"
  end

  #  it "should be applied on device" do
  #    described_class.new(:name => name).must be_appliable_to_device
  #  end

  describe "when validating attributes" do
    [ :name, :url, :config_type, :force ].each do |param|
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

    describe "for name" do
      it "should allow a valid name" do
        resource.name.should eq('config1')
      end        
    end

    describe "for url" do
      it "should allow a valid string for tftp url" do
        described_class.new(:name => resource.name, :url => 'tftp://10.10.10.10/startup.scr')[:url].should == 'tftp://10.10.10.10/startup.scr'
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :url => 'ftp://10.10.10.10/startup.scr') }.to raise_error
        expect { described_class.new(:name => resource.name, :url => '10.10.10.10/startup.scr') }.to raise_error
        expect { described_class.new(:name => resource.name, :url => '10.10.10.10/startup') }.to raise_error
        expect { described_class.new(:name => resource.name, :url => 'tftp://10.10.10.10/startup.bak') }.to raise_error
        expect { described_class.new(:name => resource.name, :url => 'tftp:/10.10.10.10/startup.scr') }.to raise_error
          #need to handle this unit test case in case
        #expect { described_class.new(:name => resource.name, :url => 'tftp://startup.scr') }.to raise_error
      end
    end

    describe 'for config_type' do
      [ :startup, :running ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :config_type => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :config_type => :start) }.to raise_error
      end
    end
    
    describe 'for force' do
      [ true, false ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :force => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :force => 'test') }.to raise_error
      end
    end  
  end  
end
