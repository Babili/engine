class JwtToken
  attr_accessor :data, :rsa_private, :expiration, :validity_period, :issued_at, :issuer, :sub, :aud

  def initialize
    @issued_at = Time.zone.now.to_i
    @issuer    = "Babili"
  end

  def generate
    @generated ||= JWT.encode(content, rsa_private, "RS256")
  end

  def to_partial_path
    "/jwt_tokens/jwt_token"
  end

  private

  def expiration
    issued_at + validity_period
  end

  def content
    {
      aud:  aud,
      sub:  sub,
      data: data,
      exp:  expiration,
      iss:  issuer,
      iat:  issued_at
    }
  end
end
