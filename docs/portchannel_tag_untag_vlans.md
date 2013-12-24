# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell PowerConnect switch module uses Network Device functionality of Puppet to interact with the PowerConnect switch.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Tag VLANs to a PortChannel
	- Untag VLANs from a PortChannel


# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Tag VLANs to a PortChannel
  		This will tag VLANs to a switch port-channel

  2. Untag VLANs from a PortChannel
  		This will untag VLANs from a switch port-channel
    

# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

	name: 
	allowvlans:
	removevlans:
    
    
# -------------------------------------------------------------------------
# Parameter signature 
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
   The following file capture the details for the sample init.pp and supported files:

    - portchannel_tag_untag_vlans.pp
	
   Sample init.pp file:
   
   class dell_powerconnect {
		dell_powerconnect::portchannel_tag_untag_vlans { '42':
		     allowvlans       => 38,
		     removevlans      => 31,
		}
	}
		

   A user can create an init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
