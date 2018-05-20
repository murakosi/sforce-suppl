class ChangeColumnToUser < ActiveRecord::Migration[5.1]
  def change

    rename_column :users, :sforce_session_id, :encrypted_sforce_session_id
    rename_column :users, :sforce_server_url, :encrypted_sforce_server_url
    rename_column :users, :sforce_metadata_server_url, :encrypted_sforce_metadata_server_url
    add_column :users, :encrypted_sforce_session_id_iv, :string, :after => :encrypted_sforce_session_id
    add_column :users, :encrypted_sforce_server_url_iv, :string, :after => :uuencrypted_sforce_server_urlid
    add_column :users, :encrypted_sforce_metadata_server_url_iv, :string, :after => :encrypted_sforce_metadata_server_url
  end
end
