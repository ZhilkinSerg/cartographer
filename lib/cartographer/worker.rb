require 'json'
require 'logger'

require 'beaneater'
require 'dotenv'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'

require 'app/models.rb'

include Cartographer::Models
Dotenv.load

module Cartographer
  class Worker
    def initialize(tube)
      @logger = Logger.new(STDERR, ENV['RACK_ENV'] == 'production' ?
                           Logger::INFO : Logger::DEBUG)
      @logger.formatter = lambda {|s, d, p, m| "#{s} -- #{m}\n" }

      log :info, 'Setting up database...'
      DataMapper.finalize
      DataMapper.setup(:default, ENV['DB_URL'])

      log :info, 'Connecting to beanstalkd...'
      @beans = Beaneater.new(ENV['BEANS_URL'])
      @beans.tubes.watch!(tube)

      @run = false
      Signal.trap('SIGTERM') do
        log :info, 'Got SIGTERM, trying to exit cleanly...'
        @run = false
      end
      Signal.trap('SIGHUP') do
        log :info, 'Got SIGHUP, running handler...'
        on_sighup
      end

      setup
    end

    def run!
      log :info, 'Entering main loop...'
      @run = true
      while @run
        begin
          job = @beans.tubes.reserve(5)
        rescue Beaneater::TimedOutError
          next
        end
        log :info, "Got job #{job.id}..." 
        data = JSON.parse(job.body.to_s, symbolize_names: true)
        process_job(data)
        job.delete
        log :info, 'Job finished'
      end
      log :info, 'Exiting cleanly...'
      @beans.close
      exit(0)
    end

    def enqueue(tube, data, delay = 0)
      @beans.tubes[tube].put(data.to_json + "\n", delay: delay)
    end

    def setup
    end

    def process_job(data)
    end

    def on_sighup
    end

    def log(level, msg)
      @logger.send(level, msg)
    end
  end
end
