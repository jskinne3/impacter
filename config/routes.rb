Rails.application.routes.draw do

  get 'beta_users/new'
  get 'beta_users/create'
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
  resources :beta_users

  get 'signup', action: :new, controller: :beta_users

end
