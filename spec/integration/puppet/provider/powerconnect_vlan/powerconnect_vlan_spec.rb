#! /usr/bin/env ruby
require 'spec_helper'
require 'yaml'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf

describe "Integration test for Dell PowerConnect switch Vlan" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))
  provider_class = Puppet::Type.type(:powerconnect_vlan).provider(:dell_powerconnect)
  let :create_vlan do
    Puppet::Type.type(:powerconnect_vlan).new(
    :name  => '52',
    :vlan_name  => 'vlan0052',
    :ensure   => 'present'
    )
  end

  let :rename_vlan do
    Puppet::Type.type(:powerconnect_vlan).new(
    :name  => '52',
    :vlan_name  => 'vlan0052Renamed',
    :ensure   => 'present'
    )
  end

  let :delete_vlan do
    Puppet::Type.type(:powerconnect_vlan).new(
    :name  => '52',
    :ensure   => 'absent'
    )
  end

  before do
    @device = provider_class.device(device_conf['url'])
  end

  context "when create,rename and delete vlan without any error" do

    it "should lookup a present powerconnect vlan" do
      result = provider_class.lookup(@device, '1')
      result[:ensure]==:present
    end

    it "should lookup a absent powerconnect vlan" do
      result = provider_class.lookup(@device, create_vlan[:name])
      result[:ensure]==:absent
    end

    it "should create a powerconnect vlan" do
      former_properties = provider_class.lookup(@device, create_vlan[:name])
      properties = get_properties(create_vlan)
      @device.switch.vlan(create_vlan[:name]).update( former_properties , properties)
      result = provider_class.lookup(@device, create_vlan[:name])
      properties.should == result
    end

    it "should rename a powerconnect vlan" do
      former_properties = provider_class.lookup(@device, rename_vlan[:name])
      properties = get_properties(rename_vlan)
      @device.switch.vlan(rename_vlan[:name]).update( former_properties , properties)
      result = provider_class.lookup(@device, rename_vlan[:name])
      properties.should == result
    end

    it "should delete the powerconnect vlan" do
      former_properties = provider_class.lookup(@device, delete_vlan[:name])
      properties = {:ensure => delete_vlan[:ensure]}
      @device.switch.vlan(delete_vlan[:name]).update( former_properties , properties)
      result = provider_class.lookup(@device, delete_vlan[:name])
      properties[:vlan_name] = properties[:ensure]
      properties.should == result
    end
  end

  def get_properties(powerconnect_vlan_obj)
    return {:vlan_name => powerconnect_vlan_obj[:vlan_name],:ensure => powerconnect_vlan_obj[:ensure]}
  end
end