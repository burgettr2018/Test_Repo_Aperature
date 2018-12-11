Rails.application.routes.draw do

  use_doorkeeper do
    controllers :tokens => 'oauth/tokens'
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, :controllers => {:confirmations => 'confirmations', :passwords => 'passwords', :unlocks => 'unlocks', :registrations => :registrations, :sessions => :sessions, :omniauth_callbacks => "omniauth_callbacks"}

  devise_scope :user do

    get 'test_abc_okta' => 'omniauth_callbacks#test_abc_okta'

    patch "/confirm" => "confirmations#confirm"
    get '/users/edit_password' => 'registrations#edit_password', as: 'edit_password_only'
    put '/users/update_password' => 'registrations#update_password', as: 'update_password_only'

    external_sso_for 'estore'
    external_sso_for 'bestroofcare'
    external_sso_for 'warranty'
    external_sso_for 'cards'
    external_sso_for 'learning'
    external_sso_for 'lms'

    get '/users/saml/sso' => 'sessions#saml', as: 'idp_saml_sso'
    post '/users/saml/sso' => 'sessions#saml'
    get '/users/saml/slo' => 'sessions#saml_slo', as: 'idp_saml_slo'
    post '/users/saml/slo' => 'sessions#saml_slo'

    get '/users/invitations/accept/:token' => 'registrations#accept_invitation', as: :accept_invitation
    put '/users/invitations/accept/:token' => 'registrations#accept_invitation_put', as: :put_accept_invitation
    get '/users/invitations/resubmit/:token' => 'registrations#resubmit_invitation_invitee', as: :resubmit_invitee
    get '/users/invitations/resend/:token' => 'registrations#resubmit_invitation_inviter', as: :resubmit_inviter

  end


  namespace :api, defaults:{format:'json'} do
    namespace :v1 do
      get '/portalsso-check' => 'portalsso#check'
      post '/portalsso-check' => 'portalsso#check_post', as: 'portalsso_check_post'
      match '/portalsso-check' => 'portalsso#check_options', via: :options

      get '/me' => "users#me"
      get '/jwt' => "users#jwt"
      get '/jwt/validate' => "users#validate_jwt"
      get '/users/show' => "users#show_by_email", as: 'old_show'
      get '/users/find' => "users#find"
      get '/users/with_permission/' => 'users#list_by_permission'
      delete '/users' => 'users#delete_user'
      get '/users/for_asm' => 'users#for_asm'
      get '/users/applications' => 'users#applications'
      get '/users/:id' => "users#show", as: :users_show, constraints: { id: /[^\/]+/ }
      post '/users' => 'users#create_with_permissions'
      patch '/users' => 'users#edit_with_permissions'
      delete '/users/permissions' => 'users#delete_user_permission'
      post '/users/virtual' => 'virtual_users#enable'
      delete '/users/virtual' => 'virtual_users#disable'
      post '/users/validate' => 'users#validate'
      delete '/users/:email' => 'users#delete_user', constraints: { email: /[^\/]+/ }
      resources :users, only: [:index], defaults: {format: :json}
    end
  end

  root :to => 'home#index'

  get '/idp' => 'home#idp', as: 'idp_landing'
  get '/users/saml/metadata' => 'home#idp_metadata', as: 'idp_metadata', defaults: {format: :xml}
  get '/users/impersonate' => 'impersonation#form'
  post '/users/impersonate/start' => 'impersonation#start'
	get '/contractor-portal/location-users' => 'impersonation#ajax_contractor_portal_location_users'
  get '/contractor-portal/locations' => 'impersonation#ajax_member_profiles'

	get '/users/internal' => 'internal#index'
  get '/users/internal/:permission_type_id/values' => 'internal#ajax_value_search'
  get '/users/internal/employees' => 'internal#ajax_employee_search'
  get '/users/internal/employees/:id' => 'internal#ajax_employee'
  post '/users/internal' => 'internal#create'

  get '/account-not-found' => 'home#account_not_found'

end
