class Powerconnect_config_fixture_with_startupconfig

  attr_accessor :powerconnect_config, :provider
  
  def initialize
    @powerconnect_config = get_powerconnect_config
    @provider = powerconnect_config.provider
  end

  private

  def  get_powerconnect_config
    Puppet::Type.type(:powerconnect_config).new(
    :name => 'config1',
    :force => 'true',
    :config_type => 'startup',
    :url => 'tftp://10.10.10.10/sss.scr'
    )
  end

end

class Powerconnect_config_fixture_with_runningconfig

  attr_accessor :powerconnect_config, :provider
  
  def initialize
    @powerconnect_config = get_powerconnect_config
    @provider = powerconnect_config.provider
  end

  private

  def  get_powerconnect_config
    Puppet::Type.type(:powerconnect_config).new(
    :name => 'config1',
    :force => 'true',
    :config_type => 'running',
    :url => 'tftp://10.10.10.10/sss.scr'
    )
  end

end