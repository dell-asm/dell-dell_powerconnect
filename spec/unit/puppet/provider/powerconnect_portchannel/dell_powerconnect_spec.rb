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

    @transport = double('transport')
    @transport.stub(:switch).and_return(@switch)
    Puppet::Provider::DellPowerconnect.stub(:transport).and_return(@transport)

    @resource = double('resource', :allowvlans => '38', :removevlans => '101')

    @provider = provider_class.new(@resource)
  end

  describe "when looking up instances at prefetch" do
    before do
      @transport.stub(:command => @transport)
    end

    it "should delegate to the portchannel fetcher" do
      @transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @portchannel.should_receive(:params_to_hash)
      provider_class.get_current('42')
    end

    it "should return the given configuration data" do
      @transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @portchannel.should_receive(:params_to_hash).and_return({ :allowvlans => '38', :removevlans => '101' })
      provider_class.get_current('42').should == { :allowvlans => '38' , :removevlans => '101' }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the configuration update method with current and past properties" do
      @instance = provider_class.new(:name => '42', :allowvlans => '38' , :removevlans => '101')
      @instance.transport.should_receive(:switch).and_return(@switch)
      @switch.should_receive(:portchannel).with('42').and_return(@portchannel)
      @switch.stub(:facts).and_return({})
      @portchannel.should_receive(:update).with({:name => '42', :allowvlans => '38', :removevlans => '101'},
        {:name => '42', :allowvlans => '38' , :removevlans => '101'})

      @instance.flush
    end
  end
end
