# == Schema Information
#
# Table name: users
#
#  id          :uuid             not null, primary key
#  platform_id :uuid
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  alive_at    :datetime
#  status      :string
#  public_id   :string           not null
#
# Indexes
#
#  index_users_on_platform_id                (platform_id)
#  index_users_on_platform_id_and_public_id  (platform_id,public_id) UNIQUE
#
# Foreign Keys
#
#  fk_user_to_platforms  (platform_id => platforms.id)
#

class User < ActiveRecord::Base
  track_entity_changes

  belongs_to :platform
  has_many   :memberships, dependent: :destroy
  has_many   :rooms, through: :memberships
  has_many   :message_user_statuses, dependent: :destroy
  has_many   :messages, through: :message_user_statuses
  has_many   :created_rooms,    class_name: "Room",    foreign_key: "initiator_id", dependent: :destroy
  has_many   :created_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy

  def self.offline
    where("status = 'offline' OR status IS NULL")
  end

  def opened_rooms
    rooms.joins(:memberships).where("memberships.open = true")
  end

  def unread_message_count
    message_user_statuses.where(read: false).count()
  end

  def alive!
    self.alive_at = Time.zone.now
    self.status   = "online"
    self.save!
  end
end
