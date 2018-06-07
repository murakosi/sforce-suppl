class AddApiVersionColumnTiUser < ActiveRecord::Migration[5.1]
  def change
      add_column :users, :api_version, :string
  end
end
