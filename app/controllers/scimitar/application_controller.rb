module Scimitar
  class ApplicationController < ActionController::Base
    before_action :require_scim
    before_action :authenticate

    protected

    def authenticated?
      authenticate_with_http_basic do |name, password|
        return handle_unauthorized unless password.present?

        name == Scimitar::Engine.username && password == Scimitar::Engine.password
      end
    end

    def authenticate
      handle_scim_error(Scimitar::AuthenticationError.new) unless authenticated?
    end

    def handle_resource_not_found(exception)
      handle_scim_error(NotFoundError.new(params[:id]))
    end

    def handle_record_invalid(error_message)
      handle_scim_error(ErrorResponse.new(status: 400, detail: "Operation failed since record has become invalid: #{error_message}"))
    end

    def handle_unauthorized
      handle_scim_error(ErrorResponse.new(status: 401, detail: "Invalid credentails"))
    end

    def handle_scim_error(error_response)
      render json: error_response, status: error_response.status
    end

    def require_scim
      unless request.format == :scim
        handle_scim_error(ErrorResponse.new(status: 406, detail: "Only #{Mime::Type.lookup_by_extension(:scim)} type is accepted."))
      end
    end
  end
end
