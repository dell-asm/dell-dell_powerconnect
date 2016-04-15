require "spec_helper"
require "puppet_x/dell_powerconnect/model/interface/base"

describe PuppetX::DellPowerconnect::Model::Interface::Base do
  let(:base) {PuppetX::DellPowerconnect::Model::Interface::Base}
  let(:transport) { stub("rspec-transport") }

  describe "#show_vlans" do
    let(:interface_type) {["Te1",0,29]}
    let(:interface_name) {interface_type.join("/")}

    it "should return a list of tagged and untagged vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport,interface_type)).to eq([[18,20,23,24,28], [29]])
    end

    it "should return a empty list when there were no tagged and untagged vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_notagged_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport,interface_type)).to eq([[], [29]])
    end

    it "should return range of tagged vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_range_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport,interface_type)).to eq([[18,20,23,24,25,28], [29]])
    end

    it "should return an empty tagged and unatagged list when there are no vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_no_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport,interface_type)).to eq([[], []])
    end
  end

  describe "#update_vlans" do

    it "should unset extra tagged vlans and add tagged vlans" do
      #tagged vlans for Example value="20" or value="20,23"
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 18").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 20 tagged").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_vlans(transport,[[18,20],[29]],["Te1",0,29],"20",true)
    end

    it "should add tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 20 tagged").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_vlans(transport,[[],[]],["Te1",0,29],"20",true)
    end

    it "should add tagged vlans and unset any untagged vlans" do
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general pvid 29").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_vlans(transport,[[],[]],["Te1",0,29],"29",false)
    end

    it "should unset untagged vlans and update untagged vlans" do
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general pvid 29").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_vlans(transport,[[],[30]],["Te1",0,29],"29",false)
    end
  end
end
