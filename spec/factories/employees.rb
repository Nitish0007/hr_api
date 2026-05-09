FactoryBot.define do
  factory :employee do
    first_name    { Faker::Name.first_name }
    last_name     { Faker::Name.last_name }
    email         { Faker::Internet.unique.email }
    job_title     { Faker::Job.title }
    country       { Faker::Address.country_code }
    salary        { Faker::Number.decimal(l_digits: 5, r_digits: 2) }
    department    { Faker::Job.field }
    hire_date     { Faker::Date.between(from: 5.years.ago, to: Date.today) }
    employee_code { "EMP-#{SecureRandom.hex(5).upcase}" }
  end
end
