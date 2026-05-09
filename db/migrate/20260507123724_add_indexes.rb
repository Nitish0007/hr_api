class AddIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :employees, :salary
    add_index :employees, :department
    add_index :employees, [ :country, :job_title ]
  end
end
