class Api::V1::EmployeesController < ApplicationController
  before_action :set_employee, only: [ :show, :update, :destroy ]

  def index
    employees = Employee.page(params[:page] || 1).per(params[:per_page] || 10)
    render_success(
      employees.map { |e| employee_data(e) },
      meta: pagination_meta(employees)
    )
  end

  def show
    render_success(@employee)
  end

  def create
    employee = Employee.new(employee_params)

    if employee.save
      render_success(
        employee,
        status: :created,
        message: "Employee created successfully"
      )
    else
      render_error(errors: employee.errors.full_messages)
    end
  end

  def update
    if @employee.update(employee_params)
      render_success(@employee, message: "Updated successfully")
    else
      render_error(errors: @employee.errors.full_messages)
    end
  end

  def destroy
    if @employee.destroy
      render_success(nil, message: "Employee deleted successfully")
    else
      render_error(errors: [ "Failed to delete employee" ])
    end
  end

  private
  def employee_params
    params.require(:employee).permit(
      :first_name, :last_name, :email, :job_title,
      :country, :salary, :department, :hire_date
    )
  end

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_data(employee)
    employee.as_json
  end
end
