# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses Network Device functionality of Puppet to interact with the PowerConnect switch.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Create VLAN
	- Remove VLAN

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create

     The create method creates a vlan on PowerConnect switch as per the parameters specified in the definition. 

   
  2. Remove

     The remove method deletes the vlan from PowerConnect switch.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

	name: (Required)ID of the VLAN.
	
    ensure: (Required) This parameter is required to call either create or remove method.
    		Possible values: present/absent
    		If its value is set to present, create method will be invoked.
    		If its value is set to absent, remove method will be invoked.

    vlan_name: Description of the VLAN
    
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Create or Remove VLANs

	node "$switch_fqdn" {
			powerconnect_vlan{
				'$vlan-id1':
					vlan_name => '$vlan1-desc',
					ensure => present;
				'$vlan-id2':
					vlan_name => '$vlan2-desc',
					ensure => present;
			}
	}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file capture the details for the sample init.pp and supported files:

    - vlan_create_remove.pp
	
   Sample init.pp file:
   
   powerconnect_vlan {
   			'5':
			vlan_name 			=> 'VLAN005',
			ensure              =>  present,
   }

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
