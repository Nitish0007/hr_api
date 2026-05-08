class Api::V1::EmployeesController < ApplicationController
  def index
    employees = Employee.page(params[:page] || 1).per(params[:per_page] || 10)
    render json: {
      data: employees,
    }, status: :ok
  end
end