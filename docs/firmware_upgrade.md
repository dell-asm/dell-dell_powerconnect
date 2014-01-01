# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses the Network Device functionality of Puppet to interact with the PowerConnect switch.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Apply Firmware Update on the Switch


# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Apply Firmware Update on the Switch
  		This functionality updates the new firmware image on the switch.

    

# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

	name: (Required)This parameter defines a dummy image name.
	 
	imageurl: This parameter defines the TFTP URL of the firmware image.
	          The value must be in the format: tftp://${TFTPServerIPAddress}/${imageLocation}
	          The image name must contain the firmware version appended to it. For example, PC7000_M6348v5.1.2.3.stk
	
	forceupdate: This parameter determines whether to force firmware update on the switch.
	             The possible values are "true' or "false". The default value is "false".
	             If this parameter is set to "true", the firmware is updated on the switch 
				 even if the firmware version that you want to update is same as the existing firmware version configured on the switch.
    
    
# -------------------------------------------------------------------------
# Parameter Signature 
# -------------------------------------------------------------------------

	node "$switch_fqdn" {

    	powerconnect_firmware{

		    '$firmware-image':
		     imageurl       => '$firmware-imageurl',
		     forceupdate    => '$firmware-force',

   		 } 
   		 
	}
	

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file contains the details of the sample init.pp and supported files:

    - firmware_upgrade.pp
	
   Sample init.pp file:
   
   powerconnect_firmware {
       'image1':
	   imageurl       => tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk,
	   forceupdate    => true,
   }
		

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
