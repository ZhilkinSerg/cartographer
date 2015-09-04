module Cartographer
  module Extensions
    autoload :Beans,  'app/extensions/beans'
    autoload :DM,     'app/extensions/dm'

    def self.registered(app)
      constants.each {|c| app.register(const_get(c)) }
    end
  end
end
