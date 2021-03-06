Rails.application.routes.draw do
 
  root :to => 'main#index'

  post    'check',                  to: 'main#check'
  get     'main',                   to: 'main#index'
  get     'refresh/sobjects',       to: 'main#refresh_sobjects'
  get     'refresh/metadata',       to: 'main#refresh_metadata'

  get     'login',                  to: 'login#login'
  post    'login',                  to: 'login#create'
  delete  'logout',                 to: 'login#destroy'

  post    'describe',               to: 'describe#describe'
  post    'describe/changelist',    to: 'describe#change'

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
  post    'upsert',                 to: 'soqlexecuter#upsert'
  post    'delete',                 to: 'soqlexecuter#delete'
  post    'undelete',               to: 'soqlexecuter#undelete'

  post    'apex',                   to: 'apex#execute'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
