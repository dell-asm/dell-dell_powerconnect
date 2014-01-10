require 'spec_helper'

describe Puppet::Type.type(:powerconnect_portchannel) do
  let(:title) { 'powerconnect_portchannel' }

  context 'should compile with given test params' do
    let(:params) { {
        :name   => '42',
        :allowvlans   => '38',
        :removevlans   => '31',
      }}
    it do
      expect {
        should compile
      }
    end

  end

  context "when validating attributes" do
    it "should have name as one of its parameters for portchannelid" do
      described_class.key_attributes.should == [:name]
    end

    describe "when validating ensure property" do
      it "should not allow non numeric values in name parameter" do
        expect { described_class.new(:name => '5abc', :allowvlans => '38') }.to raise_error Puppet::Error, /Invalid value/
      end
      it "should not allow non numeric values in allowvlans" do
        expect { described_class.new(:name => '42', :allowvlans => 'VLAN005') }.to raise_error Puppet::Error, /Invalid value/
      end
      it "should allow numeric value for allowvlans" do
        described_class.new(:name => '42', :allowvlans => '38')[:allowvlans].should == '38'
      end
      it "should not allow non numeric values in removevlans parameter" do
        expect { described_class.new(:name => '42', :removevlans => 'VLAN005') }.to raise_error Puppet::Error, /Invalid value/
      end
      it "should allow numeric value for removevlans" do
        described_class.new(:name => '42', :removevlans => '31')[:removevlans].should == '31'
      end
    end
  end
end
