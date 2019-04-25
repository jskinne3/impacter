class CreateBetaUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :beta_users do |t|
      t.string :email
      t.text :goals

      t.timestamps
    end
  end
end
