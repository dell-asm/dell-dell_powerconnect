 powerconnect_interface {
  'Gi1/0/21':
    description                        => 'ServerPort456',
    mode                               => 'general',
    mtu                                => 9216,
    remove_vlans_trunk_mode            => '30,32-35',
    add_vlans_general_mode             => '40',
    remove_interface_from_portchannel  => true,
    shutdown                           => false;
}
