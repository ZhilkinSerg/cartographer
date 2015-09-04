module Cartographer
  module Extensions
    module DM extend self
      module Helpers
        def db
          settings.database
        end
      end

      def registered(app)
        app.helpers Helpers

        DataMapper.finalize
        DataMapper::Logger.new(STDERR, :info)
        DataMapper.logger.info "Setting database at #{ENV['DB_URL']}"
        app.set :database, DataMapper.setup(:default, ENV['DB_URL'])

        if not app.production?
          require 'dm-migrations'
          DataMapper.logger.info 'Auto upgrading database...'
          Cartographer::Models.constants.each do |c|
            Cartographer::Models.const_get(c).auto_upgrade!
          end
        end
      end
    end
  end
end
