# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses the Network Device functionality of Puppet to interact with the PowerConnect switches.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Create VLAN
	- Remove VLAN

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create

     The Create method functionality creates a VLAN on the PowerConnect switch based on the parameters specified in the definition. 

   
  2. Remove

     The Remove method functionality deletes the VLAN from the PowerConnect switch.  


# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

	name: (Required) This parameter defines the ID of the VLAN.
	
    ensure: (Required) This parameter is required to call either 'create' or 'remove' method.
    		The possible values are: "present" or "absent"
    		If the value is set to "present", the 'Create' method is invoked.
    		If the value is set to "absent", the 'Remove' method is invoked.

    vlan_name: This parameter defines the description of the VLAN.
    
    
# -------------------------------------------------------------------------
# Parameter Signature 
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
   The following file contains the details of the sample init.pp and supported files:

    - vlan_create_remove.pp
	
   Sample init.pp file:
   
   powerconnect_vlan {
   			'5':
			vlan_name 			=> 'VLAN005',
			ensure              =>  present,
   }

   A user can create an init.pp file based on the above sample files and call the "puppet device" command, for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
