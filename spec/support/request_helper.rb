module RequestHelper
  def json_body
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelper, type: :request
end
