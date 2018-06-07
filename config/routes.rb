Rails.application.routes.draw do
 
  #root :to => 'login#new'
  root :to => 'main#index'

  post    'check',                  to: 'main#check'

  get     'main',                   to: 'main#index'
  post    'main',                   to: 'main#switch'

  get     'login',                  to: 'login#new'
  post    'login',                  to: 'login#create'
  delete  'logout',                 to: 'login#destroy'

  get     'describe',               to: 'describe#show'
  post    'describe',               to: 'describe#execute'
  get     'describe/changelist',    to: 'describe#change'
  post    'describe/download',      to: 'describe#download'

  get     'metadata',               to: 'metadata#show'
  post    'metadata',               to: 'metadata#list'
  get     'metadata/change',        to: 'metadata#change'
  post    'metadata/read',          to: 'metadata#read'
  post    'metadata/download',      to: 'metadata#download'
  post    'metadata/edit',          to: 'metadata#edit'

  get     'soql',                   to: 'soqlexecuter#show'
  post    'soql',                   to: 'soqlexecuter#execute'

  if Rails.env.production?
    match "*path" => redirect("/")
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
