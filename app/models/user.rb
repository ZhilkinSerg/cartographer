module Cartographer
  module Models
    class User
      include DataMapper::Resource

      property :login,  String,     key: true, length: 3..32
      property :pass,   BCryptHash

      timestamps :created_at, :updated_on

      has n, :maps
    end
  end
end
