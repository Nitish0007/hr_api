namespace :data do
  desc "Generate source text files for first and last names"
  task generate_source_files: :environment do
    # Generate 1000 unique names to provide a large enough pool for 10k combinations
    File.open("first_names.txt", "w") { |f| 1000.times { f.puts Faker::Name.unique.first_name } }
    File.open("last_names.txt", "w")  { |f| 450.times { f.puts Faker::Name.unique.last_name } }
    puts "Source files created successfully."
  end
end

# before running the seed script, you need to generate the source files first
# Command to run: docker compose -f docker-compose.dev.yml exec hr_api bin/rake data:generate_source_files
# Command to run seed script: docker compose -f docker-compose.dev.yml exec hr_api bin/rake db:seed
