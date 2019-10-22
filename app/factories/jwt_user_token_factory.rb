class JwtUserTokenFactory
  def self.build(user, platform)
    jwt_token                 = JwtToken.new
    jwt_token.rsa_private     = OpenSSL::PKey::RSA.new(platform.user_rsa_private)
    jwt_token.aud             = ["user"]
    jwt_token.sub             = user.public_id
    jwt_token.data            = { platformId: platform.id }
    jwt_token.validity_period = 86400 * 30
    jwt_token
  end
end
