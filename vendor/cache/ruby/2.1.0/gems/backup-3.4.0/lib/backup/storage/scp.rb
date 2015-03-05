# encoding: utf-8

Backup::Dependency.load('net-scp')

module Backup
  module Storage
    class SCP < Base

      ##
      # Server credentials
      attr_accessor :username, :password

      ##
      # Server IP Address and SCP port
      attr_accessor :ip, :port

      def initialize(model, storage_id = nil, &block)
        super
        instance_eval(&block) if block_given?

        @port ||= 22
        @path ||= 'backups'
        path.sub!(/^~\//, '')
      end

      private

      def connection
        Net::SSH.start(
          ip, username, :password => password, :port => port
        ) {|ssh| yield ssh }
      end

      def transfer!
        connection do |ssh|
          ssh.exec!("mkdir -p '#{ remote_path }'")

          package.filenames.each do |filename|
            src = File.join(Config.tmp_path, filename)
            dest = File.join(remote_path, filename)
            Logger.info "Storing '#{ ip }:#{ dest }'..."
            ssh.scp.upload!(src, dest)
          end
        end
      end

      # Called by the Cycler.
      # Any error raised will be logged as a warning.
      def remove!(package)
        Logger.info "Removing backup package dated #{ package.time }..."

        errors = []
        connection do |ssh|
          ssh.exec!("rm -r '#{ remote_path_for(package) }'") do |ch, stream, data|
            errors << data if stream == :stderr
          end
        end
        unless errors.empty?
          raise Errors::Storage::SCP::SSHError,
              "Net::SSH reported the following errors:\n" +
              errors.join("\n")
        end
      end

    end
  end
end
