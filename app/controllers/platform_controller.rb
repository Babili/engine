class PlatformController < ApplicationController
  before_action :authenticate

  private

  def authenticate
    return authentication_failed! unless authorization_header_valid?
    token                = authorization_header.last
    payload              = JWT.decode(token, nil, false)
    platform_id          = payload[0]["sub"]
    @current_platform    = Platform.find(platform_id)
    rsa_public           = OpenSSL::PKey::RSA.new(@current_platform.platform_rsa_public)
    verification_options = {
      algorithm:  "RS256",
      verify_iat: true,
      aud:        "platform",
      verify_aud: true
    }
    JWT.decode(token, rsa_public, true, verification_options)
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError => e
    ap e
    authentication_failed!
  end

  def current_platform
    @current_platform
  end
end
