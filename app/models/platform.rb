# == Schema Information
#
# Table name: platforms
#
#  id                            :uuid             not null, primary key
#  name                          :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  user_rsa_public               :text             not null
#  user_rsa_private              :text             not null
#  platform_rsa_public           :text             not null
#  platform_rsa_private          :text             not null
#  offline_user_message_hook_url :string
#

class Platform < ActiveRecord::Base
  track_entity_changes ignored_model_changes: [:user_rsa_public,
                                               :user_rsa_private,
                                               :platform_rsa_public,
                                               :platform_rsa_private]

  has_many :users, dependent: :destroy
  has_many :memberships, through: :users
  has_many :rooms, dependent: :destroy
  has_many :messages, -> { distinct }, through: :rooms

  def generate_jwt_token
    jwt_token                 = JwtToken.new
    jwt_token.rsa_private     = OpenSSL::PKey::RSA.new(platform_rsa_private)
    jwt_token.aud             = "platform"
    jwt_token.sub             = id
    jwt_token.validity_period = 86400 * 365 * 5
    jwt_token.generate
  end

  def has_offline_message_hook?
    offline_user_message_hook_url.present?
  end
end
