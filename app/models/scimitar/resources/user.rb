module Scimitar
  module Resources
    class User < Scimitar::Resources::Base

      set_schema Schema::User

      def self.endpoint
        '/Users'
      end

    end
  end
end
