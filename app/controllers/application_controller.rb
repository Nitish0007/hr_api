class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  private
  def render_success(data, status: :ok, meta: nil, message: nil)
    response = { data: }
    response[:meta] = meta if meta.present?
    response[:message] = message if message.present?
    render json: response, status: status
  end

  def render_error(errors: nil, status: :unprocessable_content)
    render json: { errors: }, status: status
  end

  def render_not_found(exception = nil)
    message = "Resource Not Found"
    render json: { errors: [ message ] }, status: :not_found
  end

  def render_parameter_missing(exception = nil)
    message = "Parameter missing"
    message = exception.message if exception.is_a?(ActionController::ParameterMissing)
    render json: { errors: [ message ] }, status: :bad_request
  end

  def pagination_meta(records)
    {
      total: records.total_count,
      page: records.current_page,
      per_page: records.limit_value,
      total_pages: records.total_pages
    }
  end
end
