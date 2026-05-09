

puts "Starting Seed Script..."
start_time = Time.current

first_names = File.readlines('first_names.txt', chomp: true)
last_names  = File.readlines('last_names.txt', chomp: true)

BATCH_SIZE = 2000
TOTAL_RECORDS = 10_000

job_titles = [ "Software Engineer", "DevOps Engineer", "Data Analyst", "Product manager", "Scrum Master" ]
countries = [ "IN", "US", "AU", "CA", "EN" ]

(TOTAL_RECORDS/BATCH_SIZE).times do |batch_num|
  now = Time.current
  employees = []

  BATCH_SIZE.times do |i|
    f_name = first_names.sample
    l_name = last_names.sample
    country = countries.sample
    jtitle = job_titles.sample

    employees << {
      first_name:    f_name,
      last_name:     l_name,
      email:         "#{f_name.downcase}.#{l_name.downcase}.#{SecureRandom.hex(4)}@example.com",
      job_title:     jtitle,
      country:       country,
      salary:        rand(60000..150000),
      department:    "Engineering",
      hire_date:     Date.today,
      employee_code: "EMP-#{SecureRandom.hex(6).upcase}",
      created_at:    now,
      updated_at:    now
    }
  end

  Employee.import(employees, validate: false, timestamps: false) # this is intentionally set to false to make the script faster
end

duration = Time.current - start_time
puts "Time taken: #{(duration * 1000).round(2)} ms"
puts "Done! Total employees: #{Employee.count}" # This line is to test the script ran successfully or not
