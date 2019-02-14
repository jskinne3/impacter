class ChangeKnocksWhenToDate < ActiveRecord::Migration[5.2]
  def change
  	remove_column :knocks, :when
  	add_column :knocks, :when, :date
  end
end
