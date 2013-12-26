node "power9" {
       powerconnect_config {
			'config1':
				url => 'tftp://<fqdn>/sconfig-251-26dec-1124.bak',
				force => 'true',
	            config_type => 'startup';
       }
}
