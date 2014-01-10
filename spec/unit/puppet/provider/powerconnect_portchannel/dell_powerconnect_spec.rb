require 'spec_helper'

require 'puppet/provider/powerconnect_portchannel/dell_powerconnect'
require 'puppet/provider/dell_powerconnect'


provider_class = Puppet::Type.type(:powerconnect_portchannel).provider(:dell_powerconnect)

describe provider_class do
  before do
    @portchannel = double('portchannel')
    @portchannel.stub(:name).and_return('42')
    @portchannel.stub(:params_to_hash)
    @portchannel = [ @portchannel ]

    @switch = double('switch')
    @switch.stub(:portchannel).and_return(@portchannel)
    @switch.stub(:params_to_hash).and_return({})

    @device = double('device')
    @device.stub(:switch).and_return(@switch)

    @resource = double('resource', :allowvlans => '38', :removevlans => '101')

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
      @device.stub(:command => @device)
    end

    it "should delegate to the device portchannel fetcher" do
      @device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @portchannel.should_receive(:params_to_hash)
      provider_class.lookup(@device, '42')
    end

    it "should return the given configuration data" do
      @device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @portchannel.should_receive(:params_to_hash).and_return({ :allowvlans => '38', :removevlans => '101' })
      provider_class.lookup(@device, '42').should == { :allowvlans => '38' , :removevlans => '101' }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :name => '42', :allowvlans => '38' , :removevlans => '101')
      @instance.device.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @switch.stub(:facts).and_return({})
      @portchannel.should_receive(:update).with({:name => '42', :allowvlans => '38', :removevlans => '101'},
        {:name => '42', :allowvlans => '38' , :removevlans => '101'})

      @instance.flush
    end
  end
end
