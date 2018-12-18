class CreateDoors < ActiveRecord::Migration[5.2]
  def change
    create_table :doors do |t|
      t.string :address
      t.string :zip

      t.timestamps
    end
  end
end
