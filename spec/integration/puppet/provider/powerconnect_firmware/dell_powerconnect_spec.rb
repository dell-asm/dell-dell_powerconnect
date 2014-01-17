#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf

describe "Integration test for powerconnect firmware upgrade" do

  device_conf =  YAML.load_file(my_deviceurl('dell_powerconnect','device_conf.yml'))

  before :each do
    Facter.stub(:value).with(:url).and_return(device_conf['url'])
  end

  let :upgrade_firmware do
    Puppet::Type.type(:powerconnect_firmware).new(
    :name         => 'image1',
    :imageurl     => 'tftp://172.152.0.85/PC7000_M6348v5.1.2.3.stk',
    :forceupdate  => true,
    :saveconfig   => true
    )
  end

  context "when updating firmware on switch" do

    it "should upgrade firmware" do
      upgrade_firmware.provider.get_device.connect_transport
      upgrade_firmware.provider.run(upgrade_firmware[:imageurl], upgrade_firmware[:forceupdate], upgrade_firmware[:saveconfig])
      current_version = get_version(upgrade_firmware.provider.get_device.transport.command("show running-config"))
      applied_version = upgrade_firmware[:imageurl].split("\/").last.split("v").last.split(".stk").first
      upgrade_firmware.provider.get_device.transport.close
      presense?(current_version,applied_version).should == true
    end

  end

  def presense?(response_string,key_to_check)
    retval = false
    if response_string.eql?("#{key_to_check}")
      retval = true
    else
      retval = false
    end
    return retval
  end

  def get_version(inputString)
    res = inputString.scan(/System\sSoftware\sVersion\s+(.+)/).flatten.first
    return res
  end

end

