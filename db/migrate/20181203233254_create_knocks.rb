class CreateKnocks < ActiveRecord::Migration[5.2]
  def change
    create_table :knocks do |k|
      k.string :resident_name
      k.string :neighborhood
      k.string :followup
      k.string :language
      k.string :race
      k.string :gender
      k.string :contact
      k.string :when
      k.references :door, foreign_key: true
      k.references :canvasser, foreign_key: true
      k.timestamps
    end

    create_table :questions do |q|
      q.string :description
      q.text :main_question_text
      q.text :notes_question_text
    end

    create_table :answers do |a|
      a.string :short_answer
      a.text :notes
      a.references :question, foreign_key: true
      a.references :knock, foreign_key: true
    end
  end
end
