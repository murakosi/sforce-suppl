class AddHostColumnToUser < ActiveRecord::Migration[5.1]
  def change
      remove_column :users, :is_sandbox
      add_column :users, :sforce_host, :string
  end
end
