require "digest"

# Centralizes analytics cache keys and targeted invalidation when employees change.
class AnalyticsCache
  EXPIRATION = 24.hours

  class << self
    def country_salary_key(country_code)
      code = country_code.to_s.upcase
      "country_salary/#{code}"
    end

    def job_title_average_key(country_code, job_title)
      code = country_code.to_s.upcase
      title = job_title.to_s.downcase.gsub(" ", "_")
      "job_title_avg/#{code}/#{title}"
    end

    def dashboard_statistics_key
      "dashboard_statistics"
    end

    def delete_country_salary(country_code)
      Rails.cache.delete(country_salary_key(country_code))
    end

    def delete_job_title_average(country_code, job_title)
      Rails.cache.delete(job_title_average_key(country_code, job_title))
    end

    def invalidate_for_employee(employee)
      invalidate_dashboard_statistics
      countries = []
      pairs = []

      if employee.destroyed?
        countries << employee.country
        pairs << [ employee.country, employee.job_title ]
      else
        changes = employee.saved_changes.presence || employee.previous_changes

        countries << employee.country
        pairs << [ employee.country, employee.job_title ]

        was_create = changes["id"] && changes["id"][0].nil?
        if changes.present? && !was_create
          old_country = changes["country"] ? changes["country"][0] : employee.country
          old_job = changes["job_title"] ? changes["job_title"][0] : employee.job_title
          countries << old_country if changes["country"]
          pairs << [ old_country, old_job ] if old_country.present? && old_job.present?
        end
      end

      countries.compact.uniq.each { |c| delete_country_salary(c) }
      pairs.uniq.each { |(c, j)| delete_job_title_average(c, j) if c.present? && j.present? }
    end

    def invalidate_dashboard_statistics
      Rails.cache.delete(dashboard_statistics_key)
    end
  end
end
