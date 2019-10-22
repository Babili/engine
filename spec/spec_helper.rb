require_relative  "support/json_helper"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include Requests::JsonHelper, type: :request

  config.before(:suite) do
    $platform = PlatformFactory.build(data: { attributes: { name: "Test Platform" } })
  end

  config.before(:example, :platform) do
    $platform = $platform.dup
    $platform.save!
    $headers = {
      "Authorization" => "Bearer #{$platform.generate_jwt_token}",
      "CONTENT_TYPE"  => "application/json"
    }
  end

  config.before(:example, :user) do
    $platform = $platform.dup
    $platform.save!
    $user    = UserFactory.build_from_server($platform, {})
    $user.save!
    $other_user = UserFactory.build_from_server($platform, {})
    $other_user.save!
    token    = JwtUserTokenFactory.build($user, $platform).generate
    $headers = {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE"  => "application/json"
    }
  end
end
