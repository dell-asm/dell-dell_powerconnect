#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_powerconnect/device'
require 'puppet/provider/powerconnect_portchannel/dell_powerconnect'
require 'pp'
require 'spec_lib/puppet_spec/deviceconf'
include PuppetSpec::Deviceconf


describe "Integration test for powerconnect config" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))    
  provider_class = Puppet::Type.type(:powerconnect_config).provider(:dell_powerconnect)

  before do
    @device = provider_class.device(device_conf['url']) 
  end  

  let :switch_config do
    Puppet::Type.type(:powerconnect_config).new(
    :name => 'config1',
    :url  => 'tftp://172.152.0.85/s252.scr',
    :force => 'true',
    :config_type => 'startup'
    )
  end

  context 'when applying configuration changes' do 
    it "should apply new configuration" do 
      config_instance = provider_class.new(@device, switch_config.to_hash)
      config_instance.run(switch_config[:url], switch_config[:config_type], switch_config[:force])
    end
  end

end

