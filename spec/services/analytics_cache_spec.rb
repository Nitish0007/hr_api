require "rails_helper"

RSpec.describe AnalyticsCache do
  describe ".country_salary_key" do
    it "normalizes country to uppercase" do
      expect(described_class.country_salary_key("us")).to eq("country_salary/US")
    end
  end

  describe ".job_title_average_key" do
    it "includes normalized country and a stable slug for the job title" do
      expect(described_class.job_title_average_key("us", "Software Engineer"))
        .to eq("job_title_avg/US/software_engineer")
    end
  end

  describe ".invalidate_for_employee" do
    it "deletes country and job-title keys for a destroyed employee" do
      employee = build_stubbed(:employee, country: "US", job_title: "Engineer")
      allow(employee).to receive(:destroyed?).and_return(true)

      Rails.cache.write(described_class.country_salary_key("US"), { stale: true })
      Rails.cache.write(described_class.job_title_average_key("US", "Engineer"), { stale: true })

      described_class.invalidate_for_employee(employee)

      expect(Rails.cache.read(described_class.country_salary_key("US"))).to be_nil
      expect(Rails.cache.read(described_class.job_title_average_key("US", "Engineer"))).to be_nil
    end

    it "clears country cache after salary-only update" do
      employee = create(:employee, country: "DE", job_title: "Analyst", salary: 70_000)
      Rails.cache.write(described_class.country_salary_key("DE"), { employee_count: 99 })

      employee.update!(salary: 75_000)

      expect(Rails.cache.read(described_class.country_salary_key("DE"))).to be_nil
    end

    it "clears old and new country caches when country changes" do
      employee = create(:employee, country: "FR", job_title: "Lead", salary: 80_000)
      Rails.cache.write(described_class.country_salary_key("FR"), {})
      Rails.cache.write(described_class.country_salary_key("IT"), {})

      employee.update!(country: "IT")

      expect(Rails.cache.read(described_class.country_salary_key("FR"))).to be_nil
      expect(Rails.cache.read(described_class.country_salary_key("IT"))).to be_nil
    end

    it "clears job-title cache for current and previous title when job title changes" do
      employee = create(:employee, country: "AU", job_title: "Developer", salary: 90_000)
      Rails.cache.write(described_class.job_title_average_key("AU", "Developer"), {})
      Rails.cache.write(described_class.job_title_average_key("AU", "Architect"), {})

      employee.update!(job_title: "Architect")

      expect(Rails.cache.read(described_class.job_title_average_key("AU", "Developer"))).to be_nil
      expect(Rails.cache.read(described_class.job_title_average_key("AU", "Architect"))).to be_nil
    end
  end
end
