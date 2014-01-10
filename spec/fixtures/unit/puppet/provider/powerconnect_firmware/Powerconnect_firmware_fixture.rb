class Powerconnect_firmware_fixture

  attr_accessor :powerconnect_firmware, :provider

  def initialize
    @powerconnect_firmware = get_powerconnect_firmware
	  @provider = powerconnect_firmware.provider	
  end
  
  private 
  def  get_powerconnect_firmware
    Puppet::Type.type(:powerconnect_firmware).new(
    :name               => 'image1',
    :imageurl           => 'tftp://10.10.10.10/PC7000_M6348v5.1.2.3.stk',
    :forceupdate        => 'true',
    :saveconfig         => 'true'
	)
  end
  
  public
  def get_image_url
    powerconnect_firmware[:imageurl]
  end
end
  