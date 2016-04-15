$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..','lib'))

require 'rspec-puppet'
require 'puppet_x/dell_powerconnect/model'
require 'puppet_x/dell_powerconnect/model/base'
require 'puppet_x/dell_powerconnect/transport'
require 'puppet/util/network_device/transport/ssh'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

module PuppetSpec
  FIXTURE_DIR = File.join(dir = File.expand_path(File.dirname(__FILE__)), "fixtures") unless defined?(FIXTURE_DIR)

  def self.fixture_path(fixture)
    File.join(FIXTURE_DIR, fixture)
  end

  def self.load_fixture(fixture)
    File.read(fixture_path(fixture))
  end
end

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.environmentpath = File.join(Dir.pwd, 'spec')
end
