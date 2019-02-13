class AddVanIdToKnocks < ActiveRecord::Migration[5.2]
  def change
  	add_column :knocks, :vanid, :integer
  	add_column :knocks, :dwid, :integer
  	add_column :knocks, :email, :string
  	add_column :knocks, :phone, :string
  end
end
