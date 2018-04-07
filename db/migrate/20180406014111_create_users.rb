class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.integer :is_sandbox
      t.string :sforce_session_id
      t.string :sforce_server_url
      t.string :sforce_query_locator
      t.string :user_token

      t.timestamps
    end
  end
end
