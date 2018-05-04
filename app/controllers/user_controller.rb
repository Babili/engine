class UserController < ApplicationController
  before_action :authenticate, except: [:options]

  private
  def authenticate
    return authentication_failed! unless authorization_header_valid?
    token                = authorization_header.last
    payload              = JWT.decode(token, nil, false)[0]
    user_public_id       = payload["sub"]
    return authentication_failed! unless payload["data"]
    platform_id          = payload["data"]["platformId"]
    @current_platform    = Platform.find(platform_id)
    rsa_public           = OpenSSL::PKey::RSA.new(@current_platform.user_rsa_public)
    verification_options = {
      algorithm:  "RS256",
      verify_iat: true,
      aud:        "user",
      verify_aud: true
    }
    JWT.decode(token, rsa_public, true, verification_options)
    @current_user = @current_platform.users.find_by!(public_id: user_public_id)
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError
    authentication_failed!
  end

  def current_user
    @current_user
  end

  def current_platform
    @current_platform
  end
end
