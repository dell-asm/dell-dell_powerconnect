# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses Network Device functionality of Puppet to interact with the PowerConnect switch.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Apply Configuration Update on the Switch


# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Apply Configuration Update on the Switch
  		This will update the startup or running configuration of the switch.

    

# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

	name: (Required)This parameter defines a dummy configuration name.
	 
	url: This parameter defines the TFTP URL of the switch configuration file.
	     The value must be in the format tftp://${TFTPServerIPAddress}/${configFileLocation}
	     
	config_type: This parameter determines whether the provided configuration is startup or running configuration.
	             The possible values are startup and running. The default value is running.
	             If the value is startup, then the startup configuration will be updated.
	             If the value is running, then the running configuration will be updated.
    
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

	node "$switch_fqdn" {

    	powerconnect_config{

		    '$config-image':
		     url            => '$config-url',
		     config_type    => '$config-type',

   		 } 
   		 
	}
	

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file capture the details for the sample init.pp and supported files:

    - configuration_apply.pp
	
   Sample init.pp file:
   
   powerconnect_config {
       'config1':
	   url            => 'tftp://10.10.10.10/startup.bak',
	   config_type    => 'startup',
   }
		

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
