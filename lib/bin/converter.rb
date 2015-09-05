#!/usr/bin/env ruby
# coding: utf-8

$: << File.expand_path('../' * 3, __FILE__)

require 'lib/cartographer/worker'
require 'lib/cartographer/converter'

class Break < StandardError; end

class Worker < Cartographer::Worker
  def setup
    @conv = Cartographer::Converter.new(ENV['TERRAIN_DAT'], @logger)
  end

  def process_job(data)
    unless map = Map.get(data[:id])
      log :error, "Couldn't get map #{data[:id]}"
      return false
    end

    log :debug, "Processing map #{map.id} uploaded by #{map.user.login}"

    map.state = :processing
    unless map.save
      log :warn, "Couldn't update status of map #{map.id} @ process"
      log :debug, map.errors
    end
    
    target_path = "#{ENV['WEB_STORE']}/#{map.id}.html"
    target = nil
    begin
      begin
        target = File.open(target_path, 'w')
      rescue SystemCallError => e
        log :error, "Couldn't create target file for map #{map.id}"
        log :error, e.to_s
        log :debug, e.backtrace.join("\n")
        raise Break
      end

      begin
        stats = @conv.convert(data[:path], target)
      rescue Exception => e
        log :error, "Couldn't convert map #{map.id}"
        log :error, e.to_s
        log :debug, e.backtrace.join("\n")
        raise Break
      end
      target.close

      map.state = :ready
      map.link  = ENV['WEB_LINK'] + map.id.to_s + '.html'
      map.size  = "%.2f MB" % (File.size(target_path).to_f / (1024.0 ** 2))
      map.stats = stats
      unless map.save
        log :warn, "Couldn't update status of map #{map.id} @ process/done"
        log :debug, map.errors
      end
    rescue Break
      map.state = :error
      unless map.save
        log :warn, "Couldn't update status of map #{map.id} @ process/break"
        log :debug, map.errors
      end
      enqueue('ctg-clean', data, ENV['KEEP_BROKEN'].to_i)
      if target
        target.close
        begin
          File.delete(target_path)
        rescue SystemCallError => e
          log :error, "Couldn't delete target file of map #{map.id}"
          log :error, e.to_s
          log :debug, e.backtrace.join("\n")
        end
        return false
      end
    end
    enqueue('ctg-clean', data)

    true
  end
end

Worker.new('ctg-process').run!
