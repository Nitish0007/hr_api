class Api::V1::DashboardsController < Api::V1::BaseController
  def index
    result = analytics.dashboard_statistics
    render_success(result)
  end

  private

  def analytics
    @analytics ||= AnalyticsService.new
  end
end
