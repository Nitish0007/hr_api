class Employee < ApplicationRecord
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :first_name, :job_title, :country, :department, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_REGEX }
  validates :employee_code, presence: true, uniqueness: true
  validates :salary, presence: true, numericality: { greater_than: 0 }
  validates :hire_date, presence: true # rails 7+ automatically handle date parsing and presence ensures that it a valid date not nil
end