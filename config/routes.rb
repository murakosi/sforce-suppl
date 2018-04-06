Rails.application.routes.draw do

  get 'describer/show'

  root :to => 'login#new'

  get     'login',   to: 'login#new'
  post    'login',   to: 'login#create'
  delete  'logout',  to: 'login#destroy'

  get 'soqlexecuter' => 'soqlexecuter#index'

  get 'soqlexecuter/index' => 'soqlexecuter#index'

  get 'soqlexecuter/show' => 'soqlexecuter#index'

  post 'soqlexecuter/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
