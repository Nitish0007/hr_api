require 'rails_helper'

RSpec.describe "Analytics API", type: :request do
  describe "GET /api/v1/analytics/country_salary_statistics" do
    it "returns min, max, and average salary for employees in the given country" do
      create(:employee, country: "US", salary: 50_000.00, job_title: "Analyst")
      create(:employee, country: "US", salary: 80_000.00, job_title: "Engineer")
      create(:employee, country: "US", salary: 110_000.00, job_title: "Manager")
      create(:employee, country: "CA", salary: 200_000.00, job_title: "Director")

      get "/api/v1/analytics/country_salary_statistics", params: { country: "us" }

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["country"]).to eq("US")
      expect(data["employee_count"]).to eq(3)
      expect(BigDecimal(data["minimum_salary"])).to eq(50_000)
      expect(BigDecimal(data["maximum_salary"])).to eq(110_000)
      expect(BigDecimal(data["average_salary"]).round(2)).to eq(BigDecimal("80000.00"))
    end

    it "returns null aggregates when no employees exist for the country" do
      get "/api/v1/analytics/country_salary_statistics", params: { country: "US" }

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["country"]).to eq("US")
      expect(data["employee_count"]).to eq(0)
      expect(data["minimum_salary"]).to be_nil
      expect(data["maximum_salary"]).to be_nil
      expect(data["average_salary"]).to be_nil
    end

    it "returns bad request when country is missing" do
      get "/api/v1/analytics/country_salary_statistics"

      expect(response).to have_http_status(:bad_request)
    end

    it "returns bad request when country is not a 2-letter code" do
      get "/api/v1/analytics/country_salary_statistics", params: { country: "USA" }

      expect(response).to have_http_status(:bad_request)
      expect(json_body["errors"]).to be_present
    end
  end

  describe "GET /api/v1/analytics/job_title_average_salary" do
    it "returns average salary for the job title in the given country" do
      create(:employee, country: "US", job_title: "Engineer", salary: 90_000.00)
      create(:employee, country: "US", job_title: "Engineer", salary: 110_000.00)
      create(:employee, country: "US", job_title: "Analyst", salary: 50_000.00)
      create(:employee, country: "CA", job_title: "Engineer", salary: 300_000.00)

      get "/api/v1/analytics/job_title_average_salary",
          params: { country: "US", job_title: "Engineer" }

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["country"]).to eq("US")
      expect(data["job_title"]).to eq("Engineer")
      expect(data["employee_count"]).to eq(2)
      expect(BigDecimal(data["average_salary"]).round(2)).to eq(BigDecimal("100000.00"))
    end

    it "returns zero employees and nil average when no match" do
      create(:employee, country: "US", job_title: "Analyst", salary: 50_000.00)

      get "/api/v1/analytics/job_title_average_salary",
          params: { country: "US", job_title: "Engineer" }

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["employee_count"]).to eq(0)
      expect(data["average_salary"]).to be_nil
    end

    it "returns bad request when country is missing" do
      get "/api/v1/analytics/job_title_average_salary", params: { job_title: "Engineer" }

      expect(response).to have_http_status(:bad_request)
    end

    it "returns bad request when job_title is missing" do
      get "/api/v1/analytics/job_title_average_salary", params: { country: "US" }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
