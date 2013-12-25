# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses Network Device functionality of Puppet to interact with the PowerConnect switch.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Add/Remove VLANs to Switch Interface in General Mode
	- Add/Remove VLANs to Switch Interface in Trunk Mode
	- Enable/Disable Switch Interface
	- Update Switch Interface Properties 

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Add/Remove VLANs to Switch Interface in General Mode
  		This will associate or disasocciate VLANs from a switch interface in general mode

  2. Add/Remove VLANs to Switch Interface in Trunk Mode  
  		This will associate or disasocciate VLANs from a switch interface in trunk mode
     
  3. Enable/Disable Switch Interface
  		This will enable or disable the switch interface.
  
  4. Update Switch Interface Properties 
  		This will update the MTU and description of the switch interface


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

	name: (Required)This parameter defines the name of the interface
	
	description: (Required)This parameter defines the description of the interface
	
	mode: This parameter defines the mode of the interface
	      The possible values are "general", "trunk", "access" and "private"
	      
	add_vlans_general_mode: This parameter defines the list of vlans to be mapped to an interface in general mode.
	                        This parameter can be set only if the mode parameter is either absent or set to "general".
	                        
	remove_vlans_general_mode: This parameter defines the list of vlans to be removed from an interface in general mode.
	
  	add_vlans_trunk_mode: This parameter defines the list of vlans to be mapped to an interface in trunk mode.
	                      This parameter can be set only if the mode parameter is either absent or set to "trunk".
	                      
  	remove_vlans_trunk_mode: This parameter defines the list of vlans to be removed from an interface in trunk mode.
	                         
  	add_interface_to_portchannel: This parameter defines the port-channel ID to be mapped to an interface.
  	                              The value must be an integer and in the range 1-128.
  	
  	remove_interface_from_portchannel: This parameter defines the port-channel ID to be removed from an interface.
  	                                   The possible values are true or false.The default value is false.
  	                                   If the value is true, it removes the port-channel from the interface.
  	
  	mtu: This parameter sets mtu for the interface.
		 If this parameter is present it sets the MTU value of that interface.
		 If this parameter is absent, MTU value for that interface remains unchanged.
		 MTU value must be between 1518-9216.
		 
  	shutdown: This parameter defines whether to enable or disable the interface. 
			  The possible values are true or false. The default value is "false".
			  If the value is true it disables the interface .
    
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

	node "$switch_fqdn" {

    	powerconnect_interface {

		    '$interface-id1':
		     description       => '$interface-desc',
		     mode              => '$interface-mode',
		     mtu               => $interface-mtu,
		     remove_vlans_trunk_mode   => '$interface-trunk-absentVLANs',
		     remove_vlans_general_mode: => '$interface-general-absentVLANs'
		     add_vlans_general_mode   => '$interface-general-presentVLANs',
		     remove_vlans_general_mode   => '$interface-general-absentVLANs',
		     add_interface_from_portchannel => '$interface-portchannelID'
		     remove_interface_from_portchannel => true,
		     shutdown => false
   		 } 

	}


# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file capture the details for the sample init.pp and supported files:

    - interface_configure.pp
	
   Sample init.pp file:
   
   powerconnect_interface {
			 'Gi1/0/21':
		     description       => 'ServerPort456',
		     mode              => 'general',
		     mtu               => 9216,
		     remove_vlans_trunk_mode   => '30,32-35',
		     add_vlans_general_mode   => '40',
		     remove_interface_from_portchannel => true,
		     shutdown => false;
   }

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
