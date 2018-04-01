class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :password, null: false
      t.string :login_token

      t.timestamps
    end
  end
end
