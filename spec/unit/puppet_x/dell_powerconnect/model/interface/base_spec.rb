require "spec_helper"
require "puppet_x/dell_powerconnect/model/interface/base"

describe PuppetX::DellPowerconnect::Model::Interface::Base do
  let(:base) { PuppetX::DellPowerconnect::Model::Interface::Base }
  let(:transport) { stub("rspec-transport") }

  describe "#show_vlans" do
    let(:interface_type) { ["Te1", 0, 29] }
    let(:interface_name) { interface_type.join("/") }
    it "should return a list of tagged and untagged vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport, interface_type)).to eq([[18, 20, 23, 24, 28], [29]])
    end

    it "should return a empty list of no tagged and existing untagged vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_notagged_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport, interface_type)).to eq([[], [29]])
    end

    it "should return range of tagged vlans and existing untagged vlans a list" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_range_info.out")
      transport.stub(:command).with("show running-config interface #{interface_name}").and_return(vlan_info)
      expect(base.show_vlans(transport, interface_type)).to eq([[18, 20, 23, 24, 25, 28], [29]])
    end

    it "should return an empty tagged and unatagged list when there are no vlans" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_no_info.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(vlan_info)
      expect(base.show_vlans(transport, interface_type)).to eq([[], []])
    end
  end

  describe "#update_tagged_vlans" do
    it "should unset extra tagged vlans" do
      #tagged vlans for Example value="20" or value="20,23"
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 18").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_tagged_vlans(transport, [[18, 20], [29]], ["Te1", 0, 29], "20")
    end

    it "should add tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 20 tagged").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_tagged_vlans(transport, [[], []], ["Te1", 0, 29], "20")
    end

    it "should unset extra tagged vlans" do
      #tagged vlans for Example value="20" or value="20,23"
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 18").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 20").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 28 tagged").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_tagged_vlans(transport, [[18, 20], [29]], ["Te1", 0, 29], "28")
    end
  end

  describe "#update_untagged_vlans" do
    it "should add untagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general pvid 29").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_untagged_vlans(transport, [[], []], ["Te1", 0, 29], "29")
    end

    it "should not add untagged vlan when it is already exist" do
      expect(transport).to receive(:command).never
      base.update_untagged_vlans(transport, [[], [29]], ["Te1", 0, 29], "29")
    end

    it "should set untagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general pvid 29").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show running-config interface Te1/0/29").ordered
      base.update_untagged_vlans(transport, [[], [30]], ["Te1", 0, 29], "29")
    end
  end

  describe "#update_traffic_allowed_valns" do
    it "should add untagged vlan traffic to switchport" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_nountagged_traffic.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(vlan_info)
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 29").ordered
      base.update_traffic_allowed_vlans(transport, [[], [29]], ["Te1", 0, 29], "29")
    end

    it "should update allowed untagged vlan traffic" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_update_untagged_traffic.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(vlan_info)
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 30").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan add 29").ordered
      base.update_traffic_allowed_vlans(transport, [[], [29]], ["Te1", 0, 29], "29")
    end

    it "should remove unnecessary allowed vlans to traffic" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_multi_untagged_traffic.out")
      #switchport general allowed vlan add 29,30
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(vlan_info)
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te1/0/29").ordered
      expect(transport).to receive(:command).with("switchport mode general").ordered
      expect(transport).to receive(:command).with("switchport general allowed vlan remove 30").ordered
      base.update_traffic_allowed_vlans(transport, [[], [29]], ["Te1", 0, 29], "29")
    end

    it "should not add to traffic if already exists" do
      vlan_info = PuppetSpec.load_fixture("show_interfaces_switchport/vlan_untagged_traffic.out")
      transport.stub(:command).with("show running-config interface Te1/0/29").and_return(vlan_info)
    end
  end
end

