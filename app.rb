# coding: utf-8

require 'rubygems'
require 'bundler'

Bundler.require
$: << File.expand_path('../', __FILE__)

require 'app/extensions'
require 'app/models'
require 'app/routes'

module Cartographer
  class App < Sinatra::Base
    set :environment, ENV['RACK_ENV'].to_sym

    configure do
      set :root,        File.expand_path('../', __FILE__)
      set :views,       'app/views'
      set :public_dir,  ENV['WEB_ASSETS']
      set :haml,        ugly: production?
    end

    configure :development, :staging do
      enable :static
      enable :logging
      enable :dump_errors
      enable :raise_errors
    end

    use Rack::Session::Cookie,
        key:          'cartographer',
        expire_after: 3600 * 24 * 365,
        secret:       ENV['WEB_SECRET']

    register Cartographer::Models
    register Cartographer::Extensions
    register Cartographer::Routes
  end
end
