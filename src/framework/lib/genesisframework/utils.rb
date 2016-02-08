require 'collins_client'
require 'facter'

module Genesis
  module Framework
    module Utils
      def self.tmp_path filename, sandbox = ""
        location = File.join(ENV['GENESIS_ROOT'], "tmp", sandbox)
        Dir.mkdir(location, 0755) unless File.directory? location
        File.join(location, filename)
      end

      @@config_cache = Hash.new
      @@collins_conn = nil
      @@facter = nil
      @@loggers = nil

      # mimicking rail's cattr_accessor
      def self.config_cache
        @@config_cache
      end

      def self.config_cache= (obj)
        # cull all keys to strings to ensure consistent access
        @@config_cache = obj.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}
      end

      def self.collins
        if @@collins_conn.nil?
          cfg = { :host => self.config_cache['collins']['host'], :username => self.config_cache['collins']['username'], :password => self.config_cache['collins']['password'] }
          @@collins_conn = ::Collins::Client.new(cfg)
        end

        @@collins_conn
      end

      def self.facter
        if @@facter.nil?
          @@facter = Facter.to_hash
        end

        @@facter
      end

      def self.log subsystem, message
        logline = subsystem.to_s + " :: " + message
        puts logline

        # Load external logging modules and send log to them
        if @@loggers.nil?
          @@loggers = self.config_cache['loggers'].map do |logger|
            begin
              require "logging/#{logger.downcase}"
              Logging.const_get(logger.to_sym)
            rescue LoadError
              puts "Could not load logger #{logger}"
            end
          end.compact
        end
        @@loggers.each {|logger| logger.log logline}
      end
    end
  end
end
