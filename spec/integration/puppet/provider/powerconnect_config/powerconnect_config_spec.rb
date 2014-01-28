#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_powerconnect/device'
require 'puppet/provider/powerconnect_portchannel/dell_powerconnect'
require 'pp'
require 'spec_lib/puppet_spec/deviceconf'
require 'spec_lib/puppet_spec/integrationfixture'
include PuppetSpec::Integrationfixture
include PuppetSpec::Deviceconf


describe "Integration test for powerconnect config" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))    
  provider_class = Puppet::Type.type(:powerconnect_config).provider(:dell_powerconnect)

  before do
    @device = provider_class.device(device_conf['url']) 
  end  
  
  #Load Add HBA file
  switch_config_yml =  YAML.load_file(integrationYML('dell_powerconnect', 'powerconnect_config','switch_config.yml'))

  create_node = switch_config_yml['SwitchConfig1']
    
  let :switch_config do
    Puppet::Type.type(:powerconnect_config).new(
    :name                       => create_node['name'],
    :url                        => create_node['url'],
    :force                      => create_node['force'],
    :config_type                => create_node['config_type']
    )
  end

  context 'when applying configuration changes' do 
    it "should apply new configuration" do 
      config_instance = provider_class.new(@device, switch_config.to_hash)
      result = config_instance.run(switch_config[:url], switch_config[:config_type], switch_config[:force])
      result.should eq(true)
    end
  end

end

