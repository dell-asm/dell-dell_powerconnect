require 'puppet_x/dell_powerconnect/model/vlan'

module PuppetX::DellPowerconnect::Model::Vlan::Base
  def self.register(base)
    vlan_scope = /^((\d+)\s+(.*))/

    base.register_scoped :ensure, vlan_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show vlan'
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :vlan_name, vlan_scope do
      match /^\d+\s+(\S+)/
      cmd 'show vlan'
      add do |transport, value|
        transport.command("name \"#{value}\"")
      end
      remove { |*_| }
    end
  end
end
