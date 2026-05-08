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

  describe "POST /api/v1/employees" do
    context "with valid parameters" do
      it "creates a new Employee" do
        expect {
          post "/api/v1/employees", params: { employee: valid_attributes }
        }.to change(Employee, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    
    context "with invalid parameters" do
      it "does not create an Employee and returns error" do
        expect {
          post "/api/v1/employees", params: { employee: { email: "" } }
        }.not_to change(Employee, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with duplicate data" do
      it "fails when email already exists" do
        expect {
          post "/api/v1/employees", params: { 
            employee: valid_attributes.merge(email: employee.email) 
          }
        }.not_to change(Employee, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body["errors"]).to include("Email has already been taken")
      end

      it "ignores client-provided employee_code and assigns a new unique code" do
        expect {
          post "/api/v1/employees", params: {
            employee: valid_attributes.merge(employee_code: employee.employee_code)
          }
        }.to change(Employee, :count).by(1)
        expect(response).to have_http_status(:created)
        new_employee = Employee.order(:id).last
        expect(new_employee.employee_code).not_to eq(employee.employee_code)
      end
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:new_email) { Faker::Internet.unique.email }
    let(:update_params) { { employee: { first_name: "Nitish", email: new_email } } }
    let!(:another_employee) { create(:employee) }

    it "returns not found for non-existent employee" do
      patch "/api/v1/employees/999", params: { employee: { first_name: "Updated" } }
      expect(response).to have_http_status(:not_found)
      expect(json_body["errors"]).to include("Resource Not Found")
    end

    it "updates correctly with valid params" do
      patch "/api/v1/employees/#{employee.id}", params: update_params
      expect(response).to have_http_status(:success)
      
      employee.reload
      expect(employee.first_name).to eq("Nitish")
      expect(employee.email).to eq(new_email)
    end

    it "returns error when updating email to one that already exists" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { email: another_employee.email } }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["errors"]).to include("Email has already been taken")
    end

    it "does not change employee_code when client sends a different value" do
      original_code = employee.employee_code
      patch "/api/v1/employees/#{employee.id}", params: { employee: { employee_code: "NEW-CODE-123" } }

      expect(response).to have_http_status(:success)
      expect(employee.reload.employee_code).to eq(original_code)
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the requested employee" do
      get "/api/v1/employees/#{employee.id}"
      
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["id"]).to eq(employee.id)
    end

    it "returns 404 for non-existent employee" do
      get "/api/v1/employees/9999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "successfully deletes the employee" do
      expect {
        delete "/api/v1/employees/#{employee.id}"
      }.to change(Employee, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Employee deleted successfully")
    end

    it "returns 404 if employee does not exist" do
      delete "/api/v1/employees/9999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
