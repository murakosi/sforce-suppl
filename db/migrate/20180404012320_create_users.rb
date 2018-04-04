class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.boolean :is_sandbox
      t.string :login_token

      t.timestamps
    end
  end
end
