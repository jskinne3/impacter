class AddCodeToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :van_code, :string
    add_column :questions, :van_name, :string
  end
end
