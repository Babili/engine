# == Schema Information
#
# Table name: rooms
#
#  id               :uuid             not null, primary key
#  name             :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  initiator_id     :uuid
#  platform_id      :uuid             not null
#  public_id        :string           not null
#  last_activity_at :datetime         not null
#
# Indexes
#
#  index_rooms_on_initiator_id               (initiator_id)
#  index_rooms_on_last_activity_at           (last_activity_at)
#  index_rooms_on_platform_id_and_public_id  (platform_id,public_id) UNIQUE
#
# Foreign Keys
#
#  fk_room_to_initiator_user  (initiator_id => users.id)
#  fk_room_to_platforms       (platform_id => platforms.id)
#

class Room < ActiveRecord::Base
  PER_PAGE = 20
  track_entity_changes user_metadata: {
    create: lambda do
      {
        initiator_public_id: initiator&.public_id
      }
    end
  }

  has_many   :messages, dependent: :destroy
  has_many   :memberships, dependent: :destroy
  has_many   :users, through: :memberships
  has_many   :senders, -> { distinct }, through: :messages
  belongs_to :initiator, class_name: "User", optional: true
  belongs_to :platform

  def self.find_for_platform_for_user_ids(platform, user_ids)
    find_by_sql(
      ["
        SELECT * FROM
          (
            SELECT rooms.*,  ARRAY_agg(memberships.user_id) AS user_ids FROM rooms
            LEFT JOIN memberships ON memberships.room_id = rooms.id
            WHERE rooms.platform_id = :platform_id
            GROUP BY rooms.id
          ) subquery
        WHERE user_ids <@ array[:user_ids]::uuid[]
        AND user_ids   @> array[:user_ids]::uuid[]",
        { user_ids: user_ids, platform_id: platform.id }
      ]
    ).first
  end

  def self.opened_for_user(user)
    joins(:users)
      .joins(:memberships)
      .where(memberships: {open: true, user_id: user.id}).distinct
  end

  def self.closed_for_user(user)
    joins(:users)
      .joins(:memberships)
      .where(memberships: {open: false, user_id: user.id}).distinct
  end

  def self.before_room(limit, room = nil)
    rooms = order(last_activity_at: :desc, id: :asc)
    query = "rooms.last_activity_at < ? OR (rooms.last_activity_at = ? AND rooms.id > ?)"
    rooms = rooms.where(query, room.last_activity_at, room.last_activity_at, room.id) if room
    rooms.limit(limit)
  end

  def unread_message_count_for_user(user)
    MessageUserStatus.joins(:message)
      .where(messages: {room_id: id})
      .where(user_id: user.id)
      .where(read: false)
      .count()
  end

  def opened_for_users
    users.joins(:memberships).where(memberships: {open: true}).distinct
  end

  def update_last_activity!
    self.last_activity_at = Time.zone.now
    save!
  end

  def open_for_user(user)
    users.joins(:memberships).where(memberships: {open: true, user_id: user.id}).any?
  end

  def messages_before(limit, message = nil)
    Message.previous_messages_for_room(self, limit, message)
  end
end
