Scimitar::Engine.routes.draw do
  get 'ServiceProviderConfig', to: 'service_provider_configurations#show', as: :scim_service_provider_configuration
  get 'ResourceTypes',         to: 'resource_types#index',                 as: :scim_resource_types
  get 'ResourceTypes/:name',   to: 'resource_types#show',                  as: :scim_resource_type
  get 'Schemas',               to: 'schemas#index',                        as: :scim_schemas
end
