class AnalyticsService
  def initialize(employee_scope: Employee.all)
    @employee_scope = employee_scope
  end

  def country_salary_statistics(country_code:)
    code = country_code.to_s.upcase
    Rails.cache.fetch(AnalyticsCache.country_salary_key(code), expires_in: AnalyticsCache::EXPIRATION) do
      compute_country_salary_statistics(code)
    end
  end

  def job_title_average_salary(country_code:, job_title:)
    code = country_code.to_s.upcase
    Rails.cache.fetch(
      AnalyticsCache.job_title_average_key(code, job_title),
      expires_in: AnalyticsCache::EXPIRATION
    ) do
      compute_job_title_average_salary(code, job_title)
    end
  end

  def dashboard_statistics
    result = Rails.cache.fetch(AnalyticsCache.dashboard_statistics_key, expires_in: AnalyticsCache::EXPIRATION) do
      compute_dashboard_statistics
    end

    result
  end

  private

  def compute_country_salary_statistics(country_code)
    rel = scoped_to_country(country_code)
    count = rel.count

    return empty_country_stats(country_code) if count.zero?

    min_salary, max_salary, avg_salary = rel.pick(
      Arel.sql("MIN(salary)"),
      Arel.sql("MAX(salary)"),
      Arel.sql("AVG(salary)")
    )

    {
      country: country_code,
      employee_count: count,
      minimum_salary: min_salary,
      maximum_salary: max_salary,
      average_salary: avg_salary.to_d.round(2)
    }
  end

  def compute_job_title_average_salary(country_code, job_title)
    rel = scoped_to_country(country_code).where(job_title: job_title)
    count = rel.count

    return empty_job_title_stats(country_code, job_title) if count.zero?

    avg = rel.pick(Arel.sql("AVG(salary)"))
    {
      country: country_code,
      job_title: job_title,
      employee_count: count,
      average_salary: avg.to_d.round(2)
    }
  end

  def scoped_to_country(country_code)
    @employee_scope.where(country: country_code)
  end

  def empty_country_stats(country_code)
    {
      country: country_code,
      employee_count: 0,
      minimum_salary: nil,
      maximum_salary: nil,
      average_salary: nil
    }
  end

  def empty_job_title_stats(country_code, job_title)
    {
      country: country_code,
      job_title: job_title,
      employee_count: 0,
      average_salary: nil
    }
  end

  def compute_dashboard_statistics
    result = Employee.select(
      "COUNT(*) AS total_employees",
      "AVG(salary) AS average_salary",
      "COUNT(DISTINCT department) AS total_departments",
      "COUNT(DISTINCT country) AS total_countries"
    ).take.attributes.symbolize_keys

    {
      total_employees: result[:total_employees],
      average_salary: result[:average_salary],
      total_departments: result[:total_departments],
      total_countries: result[:total_countries]
    }
  end
end
