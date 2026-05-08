class Api::V1::EmployeesController < ApplicationController
  before_action :set_employee, only: [:show, :update, :destroy]

  def index
    employees = Employee.page(params[:page] || 1).per(params[:per_page] || 10)
    render json: {
      data: employees,
    }, status: :ok
  end

  def show
    render json: { data: @employee }, status: :ok
  end

  def create
    employee = Employee.new(employee_params)

    if employee.save
      render json: {
        message: "Employee created successfully",
        data: employee
      }, status: :created
    else
      render json: {
        errors: employee.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def update
    if params[:employee].key?(:employee_code) && params[:employee][:employee_code] != @employee.employee_code
      return render json: { errors: ["Employee code cannot be changed"] }, status: :unprocessable_content
    end

    if @employee.update(employee_params)
      render json: { message: "Updated successfully", data: @employee }, status: :ok
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @employee.destroy
      render json: { message: "Employee deleted successfully" }, status: :ok
    else
      render json: { errors: ["Failed to delete employee"] }, status: :unprocessable_content
    end
  end

  private
  def employee_params
    params.require(:employee).permit(
      :first_name, :last_name, :email, :job_title, 
      :country, :salary, :department, :hire_date, :employee_code
    )
  end

  def set_employee
    @employee = Employee.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: ["Resource Not Found"] }, status: :not_found
  end
    
end