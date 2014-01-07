# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses the Network Device functionality of Puppet to interact with the PowerConnect switches.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Apply Configuration Update on the switch


# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Apply Configuration Update on the Switch
  		This method updates the startup or running configuration of the switch.

    

# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

	name: (Required)This parameter defines a dummy configuration name.
	 
	url: This parameter defines the TFTP URL of the switch configuration file.
	     The value must be in the format tftp://${TFTPServerIPAddress}/${configFileLocation}
	     
	config_type: This parameter determines whether the provided configuration is startup or running configuration.
	             The possible values are "startup" and "running". The default value is "running".
	             If the value is "startup", then the startup configuration will be updated.
	             If the value is "running', then the running configuration will be updated.
				 
	force: This parameter is used to force configuration update even when both the source and destination configuration matches
			The possible values are "true" and "false". Default value is "false".
			If the value is "false", then the configuration is only updated if the source and destinations files are different
			If the value is "true", then the configuration is updated even if both files matches.
    
    
# -------------------------------------------------------------------------
# Parameter Signature 
# -------------------------------------------------------------------------

	node "$switch_fqdn" {

    	powerconnect_config{

		    '$config-image':
		     url            => '$config-url',
		     config_type    => '$config-type',
			 force 			=> 'config-force';	
   		 } 
   		 
	}
	

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file contains the details for the sample init.pp and supported files:

    - configuration_apply.pp
	
   Sample init.pp file:
   
   powerconnect_config {
       'config1':
	   url            => 'tftp://10.10.10.10/startup.scr',
	   config_type    => 'startup',
	   force 		  => 'false';
   }
		

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
