class Employee < ApplicationRecord
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  before_validation :assign_employee_code, on: :create

  validates :first_name, :job_title, :country, :department, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_REGEX }
  validates :employee_code, presence: true, uniqueness: true
  validates :salary, presence: true, numericality: { greater_than: 0 }
  validates :hire_date, presence: true # rails 7+ automatically handle date parsing and presence ensures that it a valid date not nil

  private

  def assign_employee_code
    return if employee_code.present?

    self.employee_code = generate_unique_employee_code
  end

  def generate_unique_employee_code
    loop do
      code = "EMP-#{SecureRandom.hex(6).upcase}"
      return code unless self.class.exists?(employee_code: code)
    end
  end
end