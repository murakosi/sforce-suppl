class RemoveHostColumnFromUser < ActiveRecord::Migration[5.1]
  def change
      remove_column :users, :sforce_host
      add_column :users, :is_sandbox, :boolean
      change_column :users, :is_sandbox, :boolean, null: false
  end
end
