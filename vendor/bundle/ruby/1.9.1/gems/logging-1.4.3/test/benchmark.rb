
begin
  require 'logging'
rescue LoadError
  path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  raise if $:.include? path
  $: << path
  retry
end

begin
  require 'rubygems'
  gem 'log4r'
  require 'log4r'
  $log4r = true
rescue LoadError
  $log4r = false
end

require 'benchmark'
require 'logger'

module Logging
  class Benchmark

    def run
      this_many = 300_000

      sio = StringIO.new

      logging = ::Logging.logger sio
      logging.level = :warn

      logger = ::Logger.new sio
      logger.level = ::Logger::WARN

      log4r = if $log4r
        x = ::Log4r::Logger.new('benchmark')
        x.level = ::Log4r::WARN
        x.add ::Log4r::IOOutputter.new(
          'benchmark', sio,
          :formatter => ::Log4r::PatternFormatter.new(
            :pattern => "%.1l, [%d #\#{Process.pid}] %5l : %M\n",
            :date_pattern => "%Y-%m-%dT%H:%M:%S.\#{Time.now.usec}"
          )
        )
        x
      end

      puts "== Debug (not logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        bm.report('Logging:') {this_many.times {logging.debug 'not logged'}}
        bm.report('Logger:') {this_many.times {logger.debug 'not logged'}}
        bm.report('Log4r:') {this_many.times {log4r.debug 'not logged'}} if log4r
      end

      puts "\n== Warn (logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging.warn 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger.warn 'logged'}}
        sio.seek 0
        bm.report('Log4r:') {this_many.times {log4r.warn 'logged'}} if log4r
      end

      puts "\n== Concat ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging << 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger << 'logged'}}
        puts "Log4r:      not supported" if log4r
      end
    end

  end  # class Benchmark
end  # module Logging


if __FILE__ == $0
  bm = ::Logging::Benchmark.new
  bm.run
end

# EOF
