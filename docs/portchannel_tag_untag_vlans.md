# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses the Network Device functionality of Puppet to interact with the PowerConnect switches.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Tag VLANs to a PortChannel
	- Untag VLANs from a PortChannel


# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Tag VLANs to a PortChannel
  		This method tags the VLANs to a switch port channel.

  2. Untag VLANs from a PortChannel
  		This method untags the VLANs from a switch port channel.
    

# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

	name: (Required)This parameter defines the ID of the port channel to be configured.
	      The value must be between 1 and 128.
	       
	allowvlans: This parameter defines the list of VLANs to be tagged to the port channel.
	
	removevlans: This parameter defines the list of VLANs to be untagged from the port channel.
    
    
# -------------------------------------------------------------------------
# Parameter Signature 
# -------------------------------------------------------------------------

	node "$switch_fqdn" {

    	powerconnect_portchannel {

		    '$portchannel-id1':
		     allowvlans       => '$portchannel-allowvlans',
		     removevlans      => '$portchannel-removevlans',

   		 } 

	}
	

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following file contains the details of the sample init.pp and supported files:

    - portchannel_tag_untag_vlans.pp
	
   Sample init.pp file:
   
   powerconnect_portchannel {
       '42':
	   allowvlans       => 38,
	   removevlans      => 31,
   }
		

   A user can create an init.pp file based on the above sample files and call the "puppet device" command, for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
