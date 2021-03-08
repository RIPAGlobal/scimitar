Rails.application.routes.draw do
  namespace :scim do
    mount Scimitar::Engine, at: '/'

    get    'Users',     to: 'mock_users#index'
    get    'Users/:id', to: 'mock_users#show'
    post   'Users',     to: 'mock_users#create'
    put    'Users/:id', to: 'mock_users#update'
    delete 'Users/:id', to: 'mock_users#destroy'
  end
end
