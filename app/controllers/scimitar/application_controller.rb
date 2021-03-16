module Scimitar
  class ApplicationController < ActionController::Base

    rescue_from StandardError,                                with: :handle_unexpected_error
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_bad_json_error # Via "ActionDispatch::Request.parameter_parsers" block in lib/scimitar/engine.rb
    rescue_from Scimitar::ErrorResponse,                      with: :handle_scim_error

    before_action :require_scim
    before_action :add_mandatory_response_headers
    before_action :authenticate

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================
    #
    protected

      # You can use:
      #
      #    rescue_from SomeException, with: :handle_resource_not_found
      #
      # ...to "globally" invoke this handler if you wish.
      #
      # +_exception+:: Exception instance (currently unused).
      #
      def handle_resource_not_found(_exception)
        handle_scim_error(NotFoundError.new(params[:id]))
      end

      # This base controller uses:
      #
      #    rescue_from Scimitar::ErrorResponse, with: :handle_scim_error
      #
      # ...to "globally" invoke this handler for all Scimitar errors (including
      # subclasses).
      #
      # +error_response+:: Scimitar::ErrorResponse (or subclass) instance.
      #
      def handle_scim_error(error_response)
        render json: error_response, status: error_response.status
      end

      # This base controller uses:
      #
      #     rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_bad_json_error
      #
      # ...to "globally" handle JSON errors implied by parse errors raised via
      # the "ActionDispatch::Request.parameter_parsers" block in
      # lib/scimitar/engine.rb.
      #
      # +exception+:: Exception instance.
      #
      def handle_bad_json_error(exception)
        handle_scim_error(ErrorResponse.new(status: 400, detail: "Invalid JSON - #{exception.message}"))
      end

      # This base controller uses:
      #
      #     rescue_from StandardError, with: :handle_unexpected_error
      #
      # ...to "globally" handle 500-style cases with a SCIM response.
      #
      # +exception+:: Exception instance.
      #
      def handle_unexpected_error(exception)
        Rails.logger.error("#{exception.message}\n#{exception.backtrace}")
        handle_scim_error(ErrorResponse.new(status: 500, detail: exception.message))
      end

    # =========================================================================
    # PRIVATE INSTANCE METHODS
    # =========================================================================
    #
    private

      # Tries to be permissive in what it receives - ".scim" extensions or a
      # Content-Type header (or both) lead to both being set up for the inbound
      # request and subclass processing.
      #
      def require_scim
        if request.content_type&.downcase == Mime::Type.lookup_by_extension(:scim).to_s
          request.format = :scim
        elsif request.format == :scim
          request.headers['CONTENT_TYPE'] = Mime::Type.lookup_by_extension(:scim).to_s
        else
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
