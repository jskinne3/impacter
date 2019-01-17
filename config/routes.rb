Rails.application.routes.draw do

  devise_for :users
  root to: 'knocks#search'

  resources :knocks do
    collection do
      get 'search'
	end
  end

end
