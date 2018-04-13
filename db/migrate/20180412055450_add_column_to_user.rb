class AddColumnToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :sforce_metadata_server_url, :string
  end
end
