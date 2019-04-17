Rails.application.routes.draw do

  devise_for :users
  root to: 'knocks#search'

  resources :knocks do
    collection do
      get 'search'
      get 'report'
	end
  end
  resources :users
  resources :doors

end
