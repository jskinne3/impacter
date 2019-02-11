class AddCodeToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :code, :string
  end
end
