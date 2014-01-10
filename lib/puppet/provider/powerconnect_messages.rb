module Puppet::Provider::Powerconnect_messages

  FIRMWARE_VERSION_EXISTS_INFO="Skipping firmware update as existing firmware version is same as firmware version being applied."
  CHECK_FIRMWARE_VERSION_DEBUG="Puppet::Provider::powerconnect_firmware:Existing version = %s,Applied version = %s"
  FIRMWARE_IMAGE_DOWNLOAD_ERROR="Failed to download firmware image to switch"
  FIRMWARE_UPADTE_DOWNLOAD_DEBUG="Puppet::Provider::powerconnect_firmware:Downloading firmware image to switch"
  FIRMWARE_UPADTE_SET_BOOTIMAGE_DEBUG="Puppet::Provider::powerconnect_firmware:Setting the next active image on reboot to %s"
  FIRMWARE_UPADTE_SAVE_CONFIG_INFO="Saving switch configuration before rebooting"
  FIRMWARE_UPADTE_REBOOT_INFO="Rebooting the switch.Wait for 2 minutes."
  FIRMWARE_UPDATE_REBOOT_SUCCESSFUL_INFO="Successfully rebooted the switch."
  FIRMWARE_UPDATE_REBOOT_ERROR="Failed to reboot the switch"
  FIRMWARE_UPDATE_SUCCESSFUL_INFO="Successfully updated firmware on switch"
  POWERCONNECT_PING_SWITCH_INFO="Checking if switch is up, pinging now."
  POWERCONNECT_RECONNECT_SWITCH_DEBUG="Puppet::Provider::powerconnect_firmware:Re-established session to the switch"
  POWERCONNECT_RETRY_PING_INFO="Switch is not up, will retry after 1 min."
  POWERCONNECT_PING_SUCCESS_DEBUG="Puppet::Provider::powerconnect_firmware:Ping Succeeded, trying to reconnect to switch."
  
  
  ###Configuration messages
  CONFIG_CONFIGS_MATCH_NO_FORCE="Switch is having the same configuration as that of url configured, so configuration copy is skipped."
end
