Rails.application.routes.draw do

  get 'main', to: 'main#index'

  root :to => 'login#new'

  get     'login',   to: 'login#new'
  post    'login',   to: 'login#create'
  delete  'logout',  to: 'login#destroy'

  get   'describe',  to: 'describe#show'
  post  'describe',  to: 'describe#execute'
  get   'desc_change',    to: 'describe#change'
  get   'desc_download',  to: 'describe#download'

  get   'metadata',  to: 'metadata#show'
  post  'metadata',  to: 'metadata#execute'
  get   'meta_change',  to: 'metadata#change'
  get   'meta_download',  to: 'metadata#download'

  get   'soql',      to: 'soqlexecuter#show'
  post  'soql',      to: 'soqlexecuter#execute'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
