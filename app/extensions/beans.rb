module Cartographer
  module Extensions
    module Beans extend self
      module Helpers
        def enqueue(tube, data, delay = 0)
          settings.beans.tubes[tube].put(data.to_json + "\n", delay: delay)
        end
      end

      def registered(app)
        app.helpers Helpers

        app.set :beans, Beaneater.new(ENV['BEANS_URL'])
      end
    end
  end
end
