require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_powerconnect/device'
require 'puppet/provider/powerconnect_interface/dell_powerconnect'
require 'pp'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf

describe "Integration tests to configure Dell Powerconnect Switch Interface" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))
  provider_class = Puppet::Type.type(:powerconnect_interface).provider(:dell_powerconnect)

  let :configure_description_mode do
    Puppet::Type.type(:powerconnect_interface).new(
    :name  => 'Gi1/0/21',
    :description       => 'ServerPort21',
    :mtu => 9216,
    :mode  => 'trunk'
    )
  end

  let :configure_vlans do
    Puppet::Type.type(:powerconnect_interface).new(
    :name  => 'Gi1/0/21',
    :description          => 'ServerPort21',
    :mode                 => 'trunk',
    :mtu => 9216,
    :add_vlans_trunk_mode => '33',
    :remove_vlans_general_mode => '32,33',
    :remove_interface_from_portchannel => true
    )
  end

  let :configure_portchannel do
    Puppet::Type.type(:powerconnect_interface).new(
    :name  => 'Gi1/0/21',
    :mode => 'trunk',
    :description          => 'ServerPort21',
    :add_interface_to_portchannel => '5'
    )
  end

  before do
    @device = provider_class.device(device_conf['url'])
  end

  context "when managing interfaces" do
    it "configure interface params should work with out any error" do
      existing_params = provider_class.lookup(@device, configure_description_mode[:name])
      new_params = get_new_properties(configure_description_mode)
      @device.switch.interface(configure_description_mode[:name]).update( existing_params , new_params)
      result = provider_class.lookup(@device, configure_description_mode[:name])
      result.should include({:description => configure_description_mode[:description]})
      result.should include({:mode => configure_description_mode[:mode]})
    end
    it "configure vlans with out any error" do
      existing_params = provider_class.lookup(@device, configure_vlans[:name])
      new_params = get_new_properties(configure_vlans)
      @device.switch.interface(configure_vlans[:name]).update( existing_params , new_params)
      result = provider_class.lookup(@device, configure_vlans[:name])
      result.should include({:mode =>  configure_vlans[:mode]})
      result.should include({:add_vlans_trunk_mode =>  configure_vlans[:add_vlans_trunk_mode]})
    end
    it "configure portchannels with out any error" do
      existing_params = provider_class.lookup(@device, configure_portchannel[:name])
      new_params =  get_new_properties(configure_portchannel)
      @device.switch.interface(configure_portchannel[:name]).update( existing_params , new_params)
      result = provider_class.lookup(@device, configure_portchannel[:name])
      result.should include({:add_interface_to_portchannel =>  configure_portchannel[:add_interface_to_portchannel]})
    end
  end

  def get_new_properties(powerconnect_interface_obj)
    if powerconnect_interface_obj.eql?(configure_description_mode)
      return {:description => powerconnect_interface_obj[:description], :mtu => powerconnect_interface_obj[:mtu], :mode => powerconnect_interface_obj[:mode]}
    else if powerconnect_interface_obj.eql?(configure_vlans)
        return {:description => powerconnect_interface_obj[:description], :mtu => powerconnect_interface_obj[:mtu], :mode => powerconnect_interface_obj[:mode],:add_vlans_trunk_mode  => powerconnect_interface_obj[:add_vlans_trunk_mode ], :remove_vlans_general_mode => powerconnect_interface_obj[:remove_vlans_general_mode]}
    else
        return {:description => powerconnect_interface_obj[:description], :mtu => powerconnect_interface_obj[:mtu], :mode => powerconnect_interface_obj[:mode],:add_interface_to_portchannel=> powerconnect_interface_obj[:add_interface_to_portchannel]}
    end
  end
end
end