require 'rails_helper'

RSpec.describe Employee, type: :model do
  subject(:employee) { build(:employee) }

  describe "validations" do
    describe "uniqueness" do
      subject(:employee) { create(:employee) }
      it { should validate_uniqueness_of(:employee_code) }
      it { should validate_uniqueness_of(:email).case_insensitive }
    end
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:job_title) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:salary) }
    it { should validate_numericality_of(:salary).is_greater_than(0) }
    it { should validate_presence_of(:department) }
    it { should allow_value(Date.today).for(:hire_date) }
    it { should_not allow_value("not-a-date").for(:hire_date) }
  end

  describe "employee_code" do
    it "is assigned automatically on create when omitted" do
      emp = described_class.create!(attributes_for(:employee).except(:employee_code))
      expect(emp.employee_code).to match(/\AEMP-[A-F0-9]+\z/)
    end
  end
end
