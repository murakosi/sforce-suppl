Rails.application.routes.draw do

  root :to => 'login#new'

  get     'login',   to: 'login#new'
  post    'login',   to: 'login#create'
  delete  'logout',  to: 'login#destroy'

  get 'soqlexecuter' => 'soqlexecuter#index'

  get 'soqlexecuter/index'

  get 'soqlexecuter/show'

  post 'soqlexecuter/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
