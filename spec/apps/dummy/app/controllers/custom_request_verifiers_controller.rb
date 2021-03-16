# For tests only - uses custom 'index' implementation which returns information
# from the Rails 'request' object in its response.
#
class CustomRequestVerifiersController < Scimitar::ActiveRecordBackedResourcesController

  def index
    render json: {
      request: {
        is_scim: request.format == :scim,
        format: request.format.to_s,
        content_type: request.headers['CONTENT_TYPE']
      }
    }
  end

  def create
    # Used for invalid JSON input tests
  end

  protected

    def storage_class
      MockUser
    end

    def storage_scope
      MockUser.all
    end

end
