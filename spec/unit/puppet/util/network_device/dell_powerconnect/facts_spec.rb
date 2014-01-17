#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device'
require 'puppet/util/network_device/dell_powerconnect/facts'

describe Puppet::Util::NetworkDevice::Dell_powerconnect::Facts do

  before(:each) do
    @transport = double('transport')
    @facts = Puppet::Util::NetworkDevice::Dell_powerconnect::Facts.new(@transport)
    @transport.stub(:command)
    @transport.stub(:host).and_return("")

  end

  describe "when parsing the output of 'show system'" do
    it "should parse the sample output" do
      out = File.read(File.join(File.dirname(__FILE__), "fixtures/show_system/sample.out"))
      expected = YAML.load_file(File.join(File.dirname(__FILE__), "fixtures/show_system/sample.yaml"))
      @transport.stub(:command).with("show system", {:cache => true, :noop => false}).and_return(out)
      actual = @facts.retrieve.delete("systemuptime")
      actual == expected
    end
  end

end
