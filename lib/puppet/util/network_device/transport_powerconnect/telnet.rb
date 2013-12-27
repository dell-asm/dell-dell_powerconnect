#Module for establishing Telnet connectivity to PowerConnect switch
require 'puppet/util/network_device'
require 'puppet/util/network_device/transport_powerconnect'
require 'puppet/util/network_device/transport_powerconnect/base_powerconnect'
require 'net/telnet'

class Puppet::Util::NetworkDevice::Transport_powerconnect::Telnet < Puppet::Util::NetworkDevice::Transport_powerconnect::Base_powerconnect
    def initialize()
      super()
    end

    def handles_login?
      false
    end

    def connect
      @telnet = Net::Telnet::new("Host" => host, "Port" => port || 23,
                                 "Timeout" => 600,
                                 "Prompt" => default_prompt)
    end

    def close
      @telnet.close if @telnet
      @telnet = nil
    end

    def expect(prompt)
      lines = ''
      @telnet.waitfor(prompt) do |out|
        lines << out.gsub(/\r\n/no, "\n")
        yield out if block_given?
      end
      lines.split(/\n/).each do |line|
        Puppet.debug("telnet: IN #{line}") if Puppet[:debug]
        Puppet.fail "Executed invalid Command! For a detailed output add --debug to the next Puppet run!" if line.match(/^% Invalid input detected at '\^' marker\.$/n)
      end
      lines
    end

    def send(line, noop = false)
      #Puppet.debug("telnet: OUT #{line}") if Puppet[:debug]
      @telnet.puts(line) unless noop
    end
end
