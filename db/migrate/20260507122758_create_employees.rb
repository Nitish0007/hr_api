class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, null: false, index: { unique: true }
      t.string :job_title, null: false
      t.string :country, null: false, limit: 2
      t.decimal :salary, precision: 12, scale: 2, null: false
      t.string :department, null: false
      t.date :hire_date, null: false
      t.string :employee_code, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
