module Cartographer
  module Models
    class Stats
      include DataMapper::Resource

      property :id,         Serial
      property :hits,       Integer, default: 0
      property :downloads,  Integer, default: 0
      property :users,      Integer, default: 0
      property :maps,       Integer, default: 0
      property :failed,     Integer, default: 0

      timestamps :created_at
    end
  end
end
