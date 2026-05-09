require "rails_helper"

RSpec.describe Api::V1::PublicResourcesController, type: :request do
  describe "GET /api/v1/public_resources/allowed_resource_list" do
    it "returns a list of allowed departments" do
      get "/api/v1/public_resources/allowed_resource_list?resource=departments"
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(15)
    end

    it "returns a list of allowed job titles" do
      get "/api/v1/public_resources/allowed_resource_list?resource=job_titles"
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(7)
    end

    it "returns a list of allowed countries" do
      get "/api/v1/public_resources/allowed_resource_list?resource=countries"
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(14)
    end

    it "returns an error if the resource is not found" do
      get "/api/v1/public_resources/allowed_resource_list?resource=random_resource"
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["errors"]).to include("Invalid 'resource' name")
    end
  end
end