Scimitar::Engine.routes.draw do
  get 'ServiceProviderConfig', to: 'service_provider_configurations#show'
  get 'ResourceTypes',         to: 'resource_types#index'
  get 'ResourceTypes/:name',   to: 'resource_types#show', as: :scim_resource_type
  get 'Schemas',               to: 'schemas#index',       as: :scim_schemas
end
