class ResourceService
  attr_accessor :name, :errors

  def initialize(name)
    @errors = []
    @errors << "Resource name required" if name.blank?
    @errors << "Invalid 'resource' name" unless valid_resources.include?(name)
    @name = name
  end

  def fetch_list
    return { errors: @errors } unless @errors.blank?
    resources = YAML.load_file(Rails.root.join("config/resources/#{@name}.yml"))
    resources.map { |key, value| { id: key, name: value } }
  end

  private
  def valid_resources
    %w[departments job_titles countries]
  end
end
