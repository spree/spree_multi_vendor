Spree::Core::Engine.add_routes do
  # admin panel routes
  namespace :admin, path: Spree.admin_path do
    resources :vendors do
      collection do
        get :select_options, defaults: { format: :json }
      end
      member do
        get :edit_commission_rate
        get :edit_payouts_schedule
        get :edit_returns_address
        get :edit_billing_address
        get :edit_returns_policy
        get :edit_brand
        patch :approve
        patch :reject
        patch :suspend
        patch :archive
        patch :confirm_shipping_rates
        patch :use_no_external_store
      end
      resources :products, only: %i[index]
      resources :orders, only: [:index]

      resources :role_users, only: [:destroy]
    end
    resource :vendor_settings, only: [:edit, :update], controller: 'vendor_settings'

    resource :marketplace_settings, only: [:edit, :update], controller: 'marketplace_settings'
  end

  # api routes
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :platform do
        resources :vendors do
          member do
            patch :invite
            patch :start_onboarding
            patch :complete_onboarding
            patch :approve
            patch :reject
            patch :suspend
          end
        end
      end

      namespace :storefront do
        resources :vendors, only: [:show, :index]
      end
    end
  end
end
