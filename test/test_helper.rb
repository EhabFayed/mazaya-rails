ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  # Logs in an admin (or the given role) for /admin requests.
  def sign_in_admin(role: "admin")
    user = User.create!(name: "Test #{role}", email: "#{role}-#{SecureRandom.hex(3)}@test.local", password: "secret-pass-123", role: role)
    post admin_login_path, params: { email: user.email, password: "secret-pass-123" }
    user
  end
end
