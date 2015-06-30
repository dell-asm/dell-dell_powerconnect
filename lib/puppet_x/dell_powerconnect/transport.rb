module PuppetX
  module DellPowerconnect
    class Transport
      attr_accessor :session, :enable_password, :switch
      def initialize(certname, options={})
        if options[:device_config]
          device_conf = options[:device_config]
        else
          require 'asm/device_management'
          device_conf = ASM::DeviceManagement.parse_device_config(certname)
        end

        @enable_password = options[:enable_password] || device_conf[:arguments]['enable']

        unless @session
          require "puppet_x/dell_powerconnect/transport/ssh"
          @session = PuppetX::DellPowerconnect::Transport::Ssh.new
          @session.host = device_conf[:host]
          @session.port = device_conf[:port] || 22
          if device_conf[:arguments]['credential_id']
            require 'asm/cipher'
            cred = ASM::Cipher.decrypt_credential(device_conf[:arguments]['credential_id'])
            @session.user = cred.username
            @session.password = cred.password
          else
            @session.user = device_conf[:user]
            @session.password = device_conf[:password]
          end
        end

        @session.default_prompt = /[#>]\s?\z/n
        connect_session
        init_facts
        init_switch
      end

      def connect_session
        session.connect
        login
        enable
        session.command("terminal length 0", :noop => false)
      end

      def login
        return if session.handles_login?
        if @session.user != ''
          session.command(@session.user, {:prompt => /^Password:/, :noop => false})
        else
          session.expect(/^Password:/)
        end
        session.command(@session.password, :noop => false)
      end

      def enable
        session.command("enable", {:noop => false}) do |out|
          out.each_line do |line|
            if line.start_with?("Password:")
              raise "Can't issue \"enable\" to enter privileged, no enable password set" unless enable_password
              session.send(enable_password+"\r")
              return
            end
          end
        end
      end

      def init_switch
        require 'puppet_x/dell_powerconnect/model/switch'
        @switch ||= PuppetX::DellPowerconnect::Model::Switch.new(session, @facts.facts_to_hash)
        @switch.retrieve
      end

      def init_facts
        require 'puppet_x/dell_powerconnect/facts'
        @facts ||= PuppetX::DellPowerconnect::Facts.new(session)
        @facts.retrieve
      end

      def facts
        @facts.facts_to_hash
      end
    end
  end
end