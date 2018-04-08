Rails.application.routes.draw do

  root :to => 'login#new'

  get     'login',   to: 'login#new'
  post    'login',   to: 'login#create'
  delete  'logout',  to: 'login#destroy'

  get  'describe',  to: 'describer#show'
  get  'change', to: 'describer#change'
  post  'change', to: 'describer#change'
  post 'describe',  to: 'describer#execute'

  get 'download', to: 'describer#download'
  get 'soqlexecuter' => 'soqlexecuter#index'

  get 'soqlexecuter/index' => 'soqlexecuter#index'

  get 'soqlexecuter/show' => 'soqlexecuter#index'

  post 'soqlexecuter/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
