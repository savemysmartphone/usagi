require 'logger'

module Usagi
  class << self
    attr_accessor :pid, :port, :rspec

    def start
      @port = (rand * 65535).to_i until defined?(@port) && @port > 1024
      @pid = IO.popen([{'RAILS_ENV' => 'test'},['rails', 'bundle'], 'server', '-p', @port.to_s]).pid
      puts "[usagi][#{@pid}] Running rails server on port #{@port}"

      Signal.trap('INT') do
        stop
        Process.exit
      end

      sleep 1 until `curl --silent "localhost:#{@port}"`.length > 0

      puts "[usagi][#{@pid}] Rails server listening on port #{@port}"
      true
    end

    def stop
      begin
        Process.kill('INT', @pid)
        puts "[usagi][#{@pid}] SIGINT sent to rails server"
        puts "[usagi][#{@pid}] Waiting for rails server to ack kill command..."
        Process.wait(Usagi.pid)
      rescue
      end
      puts "[usagi][#{@pid}] Killed rails server"
    end
  end
end

require 'usagi/api_response'
require 'usagi/rspec' if defined? RSpec
