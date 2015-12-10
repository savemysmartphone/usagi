require 'logger'

module Usagi
  class << self
    attr_accessor :pid, :port, :rspec, :suite_options, :options

    def start(*opts)
      @options = {}
      opts.each{|opt| @options[opt.gsub(/^--usagi-/,'').gsub('-','_').to_sym] = true }
      @port = (rand * 65535).to_i until defined?(@port) && @port > 1024
      @io = IO.popen([{'RAILS_ENV' => 'test'},['rails', 'bundle'], 'server', '-p', @port.to_s])
      Thread.new(@io) do |rails_io|
        buffer = ''
        until rails_io.eof?
          buffer += rails_io.readpartial(1024)
          while buffer["\n"]
            minibuf = buffer.split("\n").first
            buffer = buffer[(minibuf.length + 1)..-1]
            puts "[rails]>> #{minibuf}"
          end
        end
        puts "[rails]>> #{buffer}" if buffer.length > 0
      end if Usagi.options[:rails_output]
      @pid = @io.pid
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

    def options
      @options ||= {}
    end

    def suite_options
      @suite_options ||= {}
    end

    # Matchers methods
    def define_matcher(name, &block)
      if matchers[name.to_s.upcase]
        raise ArgumentError("already defined matcher #{name.to_s.upcase}")
      end
      matchers[name.to_s.upcase] = Matcher.new(name.to_s.upcase, &block)
    end

    def remove_matcher(name)
      unless matchers[name.to_s.upcase]
        raise ArgumentError("undefined matcher #{name.to_s.upcase}")
      end
      matchers.delete(name.to_s.upcase)
    end

    def rename_matcher(old_name, new_name)
      unless matchers[old_name.to_s.upcase]
        raise ArgumentError("undefined matcher #{old_name.to_s.upcase}")
      end
      matchers[new_name.to_s.upcase] = matchers.delete(old_name.to_s.upcase)
    end

    def matchers
      @matchers ||= MatcherContainer.new
    end
  end
end

require 'usagi/api_response'
require 'usagi/rspec' if defined? RSpec
