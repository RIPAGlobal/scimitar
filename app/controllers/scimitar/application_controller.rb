module Scimitar
  class ApplicationController < ActionController::Base

    before_action :require_scim
    before_action :add_mandatory_response_headers
    before_action :authenticate

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================
    #
    protected

      def handle_resource_not_found(exception)
        handle_scim_error(NotFoundError.new(params[:id]))
      end

      def handle_record_invalid(error_message)
        handle_scim_error(ErrorResponse.new(status: 400, detail: "Operation failed since record has become invalid: #{error_message}"))
      end

      def handle_scim_error(error_response)
        render json: error_response, status: error_response.status
      end

    # =========================================================================
    # PRIVATE INSTANCE METHODS
    # =========================================================================
    #
    private

      def require_scim
        unless request.format == :scim
          handle_scim_error(ErrorResponse.new(status: 406, detail: "Only #{Mime::Type.lookup_by_extension(:scim)} type is accepted."))
        end
      end

      def add_mandatory_response_headers

        # https://tools.ietf.org/html/rfc7644#section-2
        #
        #   "...a SCIM service provider SHALL indicate supported HTTP
        #   authentication schemes via the "WWW-Authenticate" header."
        #
        # Rack may not handle an attempt to set two instances of the header and
        # there is much debate on how to specify multiple methods in one header
        # so we just let Token override Basic (since Token is much stronger, or
        # at least has the potential to do so) if that's how Rack handles it.
        #
        # https://stackoverflow.com/questions/10239970/what-is-the-delimiter-for-www-authenticate-for-multiple-schemes
        #
        response.set_header('WWW_AUTHENTICATE', 'Basic' ) if Scimitar.engine_configuration.basic_authenticator.present?
        response.set_header('WWW_AUTHENTICATE', 'Bearer') if Scimitar.engine_configuration.token_authenticator.present?
      end

      def authenticate
        handle_scim_error(Scimitar::AuthenticationError.new) unless authenticated?
      end

      def authenticated?
        result = if Scimitar.engine_configuration.basic_authenticator.present?
          authenticate_with_http_basic(&Scimitar.engine_configuration.basic_authenticator)
        end

        result ||= if Scimitar.engine_configuration.token_authenticator.present?
          authenticate_with_http_token(&Scimitar.engine_configuration.token_authenticator)
        end

        return result
      end

  end
end
