 powerconnect_interface {
  'interface-name':
    description                        => 'description',
    mode                               => 'general',
    mtu                                => 9216,
    remove_vlans_trunk_mode            => '30,32-35',
    add_vlans_general_mode             => '40',
    remove_interface_from_portchannel  => true,
    shutdown                           => false;
}
