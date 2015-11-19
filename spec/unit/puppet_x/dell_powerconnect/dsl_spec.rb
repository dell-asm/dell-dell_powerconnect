require 'spec_helper'
require 'puppet_x/dell_powerconnect/dsl'

describe PuppetX::DellPowerconnect::Dsl do
  let(:fact_fixtures) {File.join(PuppetSpec::FIXTURE_DIR,"unit","puppet_x","dell_powerconnect")}
  let(:show_interface_status) { File.read(File.join(fact_fixtures, "show_interface_status.out"))}

  describe "#vlan_information" do
    it "should return the correct fact data" do
      vlan_information = Class.new.extend(PuppetX::DellPowerconnect::Dsl).vlan_information(show_interface_status)
      expect(vlan_information).to include("25")
      expect(vlan_information["25"]).to eq({
        "tagged_tengigabit" => "Te1/0/17,Te1/0/18,Te1/0/33",
        "untagged_tengigabit" => "Te1/0/9,Te1/0/13,Te1/0/14,Te1/0/15,Te1/0/16,Te1/0/20,Te1/0/25,Te1/0/31,Te1/0/34,Te1/0/35,Te1/0/36,Te1/0/39",
        "tagged_fortygigabit" => {},
        "untagged_fortygigabit" => {},
        "tagged_portchannel" => {},
        "untagged_portchannel" => {}
                                           })
    end
  end
end