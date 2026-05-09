class Api::V1::PublicResourcesController < ApplicationController
  def allowed_resource_list
    resource = params[:resource]
    resources = ResourceService.new(resource).fetch_list
    return render_error(errors: resources[:errors]) if resources.is_a?(Hash) && resources[:errors].any?
    render_success(resources, status: :ok)
  end
end
