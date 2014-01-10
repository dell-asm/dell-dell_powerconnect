require 'spec_helper'

require 'puppet/provider/powerconnect_vlan/dell_powerconnect'

provider_class = Puppet::Type.type(:powerconnect_vlan).provider(:dell_powerconnect)

describe provider_class do
  before do
    @vlan =  double("vlan", :name => '5',:params_to_hash => {})
    @vlans = [ @vlan ]

    @switch = double("switch", :vlan => @vlans,:params_to_hash => {})
    
    @device = double("device", :switch => @switch)
    
    @resource = double("resource", :vlan_name => 'VLAN005')
    
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

    it "should delegate to the device vlan fetcher" do    
      @device.should_receive(:switch).and_return(@switch)      
      @switch.should_receive(:vlan).with('5').and_return(@vlan)      
      @vlan.should_receive(:params_to_hash)
      provider_class.lookup(@device, '5')
    end

    it "should return the given configuration data" do      
      @device.should_receive(:switch).and_return(@switch)      
      @switch.should_receive(:vlan).with('5').and_return(@vlan)      
      @vlan.should_receive(:params_to_hash).and_return({ :vlan_name => "VLAN005" })
      provider_class.lookup(@device, '5').should == { :vlan_name => "VLAN005" }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :ensure => :present, :name => '5', :vlan_name => "VLAN005")
      @instance.resource = @resource
      @resource.stub(:[]).with(:name).and_return('5')
      @instance.stub(:device).and_return(@device)
      @switch.should_receive(:vlan).with('5').and_return(@vlan)
      @switch.stub(:facts).and_return({})
      @vlan.should_receive(:update).with({:ensure => :present, :name => '5', :vlan_name => "VLAN005"},
                                  {:ensure => :present, :name => '5', :vlan_name => "VLAN005again"})
      @vlan.should_receive(:update).never

      @instance.vlan_name = "VLAN005again"
      @instance.flush
    end
  end
end
