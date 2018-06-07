class ChangeSandboxColumnOfUser < ActiveRecord::Migration[5.1]
  def change
  	rename_column  :users, :is_sandbox, :sandbox
  end
end
