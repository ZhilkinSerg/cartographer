module Cartographer
  module Models
    class Stats
      include DataMapper::Resource

      property :id,         Serial
      property :hits,       Integer
      property :users,      Integer
      property :maps,       Integer
      property :errors,     Integer
      property :downloads,  Integer

      timestamps :created_at
    end
  end
end
