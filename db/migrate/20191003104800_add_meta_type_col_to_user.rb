class AddMetaTypeColToUser < ActiveRecord::Migration[5.1]
  def change
  	add_column :users, :metadata_types, :text, default: [].to_yaml
  end
end
