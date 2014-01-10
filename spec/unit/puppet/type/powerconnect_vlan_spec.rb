require 'spec_helper'

describe Puppet::Type.type(:powerconnect_vlan) do
  let(:title) { 'powerconnect_vlan' }

  context 'should compile with given test params' do
    let(:params) { {
        :name   => '5',
        :vlan_name   => 'VLAN005',
        :ensure   => 'present',
      }}
    it do
      expect {
        should compile
      }
    end

  end

  context "when validating attributes" do
    it "should have name as one of its parameters for vlanid" do
      described_class.key_attributes.should == [:name]
    end
   
    it "should not allow non numeric values in name parameter" do
      expect { described_class.new(:name => '5abc', :vlan_name => 'VLAN005', :ensure => 'present') }.to raise_error Puppet::Error, /Invalid value/
    end
    
    it "should allow numeric/non numeric values in vlan_name parameter" do
      described_class.new(:name => '5', :vlan_name => 'VLAN005', :ensure => 'present')[:vlan_name].should == "VLAN005"
    end
    
    
    describe "when validating ensure property" do
      it "should support present" do
        described_class.new(:name => '5', :vlan_name => 'VLAN005', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:name => '5', :vlan_name => 'VLAN005', :ensure => 'absent')[:ensure].should == :absent
      end
      
      it "should not allow support any value other than present/absent" do
      expect { described_class.new(:name => '5', :vlan_name => 'VLAN005', :ensure => 'present123') }.to raise_error Puppet::Error, /Invalid value/
    end
           
    
    end
  end
end

