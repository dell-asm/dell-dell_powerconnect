require "spec_helper"
require "puppet_x/dell_powerconnect/model/interface/base"

describe PuppetX::DellPowerconnect::Model::Interface::Base do

  let(:base) {PuppetX::DellPowerconnect::Model::Interface::Base}
  let(:transport) { stub("rspec-transport") }

  describe "#show_vlans" do
    interface_type=["Te1",0,29]
    it "should return a list of tagged and untagged vlans" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_info.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(out)
      expect(base.show_vlans(transport,interface_type)).to eq([[18,20,23,24,28], [29]])
    end
    it "should return a empty list when there were no tagged and untagged vlans" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_notagged_info.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(out)
      expect(base.show_vlans(transport,interface_type)).to eq([[], [29]])
    end
    it "should return range of tagged vlans" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_range_info.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(out)
      expect(base.show_vlans(transport,interface_type)).to eq([[18,20,23,24,25,28], [29]])
    end
  end

  describe "#update_vlans" do
    it "should remove extra tagged vlans and update" do
      #tagged vlans for Example value="20" or value="20,23"
      value="20"
      interface_type=["Te1",0,29]
      existing_vlans=[[18,20],[29]]
      tagged=true
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 18").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_vlans(transport,existing_vlans,interface_type,value,tagged)
    end
  end
end
