Rails.application.routes.draw do
 
  #root :to => 'login#new'
  root :to => 'main#index'

  post    'check',                  to: 'main#check'
  get     'main',                   to: 'main#index'
  get     'refresh_sobjects',       to: 'main#refresh_sobjects'

  get     'login',                  to: 'login#new'
  post    'login',                  to: 'login#create'
  delete  'logout',                 to: 'login#destroy'

  post    'describe',               to: 'describe#describe'
  post    'describe/changelist',    to: 'describe#change'

  get     'metadata',               to: 'metadata#show'
  get     'metadata/change',        to: 'metadata#change'
  post    'metadata',               to: 'metadata#list'
  post    'metadata/read',          to: 'metadata#read'
  post    'metadata/edit',          to: 'metadata#edit'
  post    'metadata/crud',          to: 'metadata#crud'
  post    'metadata/retrieve',      to: 'metadata#retrieve'
  post    'metadata/retrieve_check',
                                    to: 'metadata#check_retrieve_status'
  post    'metadata/retrieve_result',
                                    to: 'metadata#retrieve_result'
  post    'metadata/deploy',        to: 'metadata#deploy'
  post    'metadata/deploy_check',  to: 'metadata#check_deploy_status'

  get     'create',                 to: 'soqlexecuter#create'
  post    'query',                  to: 'soqlexecuter#query'
  post    'update',                 to: 'soqlexecuter#update'
  post    'delete',                 to: 'soqlexecuter#delete'
  post    'undelete',               to: 'soqlexecuter#undelete'
  post    'parse',                  to: 'soqlexecuter#parse'

  post    'tooling',                to: 'tooling#execute'

  post    'apex',                   to: 'apex#execute'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
