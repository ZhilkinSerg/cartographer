#!/usr/bin/env ruby
# coding: utf-8

$: << File.expand_path('../' * 3, __FILE__)

require 'fileutils'

require 'lib/cartographer/worker'

class Worker < Cartographer::Worker
  def process_job(data)

    log :debug, "Removing directory #{data[:path]}"
    begin
      FileUtils.remove_entry_secure(data[:path], true)
    rescue Exception => e
      log :error, e.to_s
      log :debug, e.backtrace.join("\n")
    end
  end
end

Worker.new('ctg-clean').run!
