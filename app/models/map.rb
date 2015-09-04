module Cartographer
  module Models
    class Map
      include DataMapper::Resource

      property :id,         Serial
      property :state,      Enum[:ready, :waiting, :processing, :error], \
                              default: :waiting
      property :link,       URI
      property :size,       String
      property :stats,      String
      property :comment,    Text
      property :downloads,  Integer

      timestamps :created_at, :updated_on

      belongs_to :user
    end
  end
end
