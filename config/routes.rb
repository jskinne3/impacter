Rails.application.routes.draw do

  devise_for :users
  root to: 'welcome#index'

  resources :knocks do
    collection do
      get 'search'
      get 'report'
	end
  end
  resources :users
  resources :doors


get 'beta', action: :beta, controller: :welcome

end
