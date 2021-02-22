module Scimitar
  module Errors
    def add_errors_from_hash(errors_hash, prefix: nil)
      errors_hash.each_pair do |key, value|
        new_key = prefix.nil? ? key : "#{prefix}.#{key}".to_sym
        if value.is_a?(Array)
          value.each {|error| errors.add(new_key, error)}
        else
          errors.add(new_key, value)
        end
      end
    end
  end
end
