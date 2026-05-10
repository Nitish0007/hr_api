# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "noreply@example.com"
  require "devise/orm/active_record"

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth, :params ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.sign_out_via = :delete
  config.navigational_formats = []
  config.parent_controller = "ApplicationController"

  jwt_secret = ENV["DEVISE_JWT_SECRET_KEY"].presence || Rails.application.credentials.dig(:devise_jwt_secret_key).presence

  if jwt_secret.blank?
    unless Rails.env.development? || Rails.env.test?
      raise "Set DEVISE_JWT_SECRET_KEY or credentials devise_jwt_secret_key"
    end

    jwt_secret = "local-only-devise-jwt-secret-must-be-at-least-32-chars"
  end

  config.jwt do |jwt|
    jwt.secret = jwt_secret
    jwt.dispatch_requests = [
      [ "POST", %r{^/api/v1/auth/login$} ],
      [ "POST", %r{^/api/v1/auth/sign_up$} ]
    ]
    jwt.revocation_requests = [
      [ "DELETE", %r{^/api/v1/auth/logout$} ]
    ]
    jwt.expiration_time = 24.hours.to_i
    jwt.request_formats = { user: [ :json, nil ] }
  end

  config.warden do |manager|
    manager.failure_app = AuthFailureApp
  end
end
