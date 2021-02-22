module Scimitar
  module Resources
    class Group < Base

      set_schema Schema::Group

      def self.endpoint
        "/Groups"
      end

    end
  end
end
