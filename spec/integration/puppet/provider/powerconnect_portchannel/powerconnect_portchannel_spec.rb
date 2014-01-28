#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_powerconnect/device'
require 'puppet/provider/powerconnect_portchannel/dell_powerconnect'
require 'spec_lib/puppet_spec/deviceconf'
include PuppetSpec::Deviceconf


describe "Integration test for powerconnect portchannel" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))    
  provider_class = Puppet::Type.type(:powerconnect_portchannel).provider(:dell_powerconnect)

  before do
    @device = provider_class.device(device_conf['url'])   
  end  

  let :config_portchannel do
    Puppet::Type.type(:powerconnect_portchannel).new(
    :name  => '47',
    :allowvlans => '33',
    :removevlans => '152'
    )
  end

  context 'when configuring portchannel' do 
    it "should configure portchannel" do 
      expectedResult = {:allowvlans => config_portchannel[:allowvlans], :removevlans => config_portchannel[:removevlans]}
      preresult = provider_class.lookup(@device, config_portchannel[:name])
      @device.switch.portchannel(config_portchannel[:name]).update(preresult,{:allowvlans => config_portchannel[:allowvlans], :removevlans => config_portchannel[:removevlans]})
      postresult = provider_class.lookup(@device, config_portchannel[:name])
      postresult.should eq(expectedResult)
    end
  end

end

