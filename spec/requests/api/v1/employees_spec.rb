require 'rails_helper'

RSpec.describe "Employees API", type: :request do
  let(:valid_attributes) { attributes_for(:employee) }
  let!(:employee) { create(:employee) }

  describe "GET /api/v1/employees" do
    it "returns a successful response" do
      get "/api/v1/employees"
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end
  end
end
