# == Schema Information
#
# Table name: messages
#
#  id                :uuid             not null, primary key
#  room_id           :uuid
#  sender_id         :uuid
#  content           :text
#  content_type      :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  public_id         :string           not null
#  sequence_number   :integer          not null
#  device_session_id :string
#
# Indexes
#
#  index_messages_on_room_id                (room_id)
#  index_messages_on_room_id_and_public_id  (room_id,public_id) UNIQUE
#  index_messages_on_sender_id              (sender_id)
#  index_messages_on_sequence_number        (sequence_number) UNIQUE
#
# Foreign Keys
#
#  fk_message_to_rooms    (room_id => rooms.id)
#  fk_message_to_senders  (sender_id => users.id)
#

class Message < ActiveRecord::Base
  track_entity_changes user_metadata: {
    create: lambda do
      {
        room_public_id:       room.public_id,
        sender_public_id:     sender&.public_id,
        recipient_public_ids: recipients.map(&:public_id),
        platform_id:          platform_id
      }
    end
  }

  PER_PAGE = 15

  belongs_to :room, optional: true
  belongs_to :sender, class_name: "User", optional: true
  has_many   :message_user_statuses, dependent: :destroy
  has_many   :users, through: :message_user_statuses

  def notified_to(user_id)
    MessageUserStatus.mark_as_notified(user_id, id)
  end

  def has_been_notified_to?(user_id)
    message_user_statuses.where(user_id: user_id)
                         .where(notified: true)
                         .exists?
  end

  def has_been_read_by?(user_id)
    message_user_statuses.where(user_id: user_id)
                         .where(read: true)
                         .exists?
  end

  def recipients
    message_user_statuses.map(&:user).select do |user|
      user != sender
    end
  end

  def self.unnotified_for_user(user_id)
    joins(:message_user_statuses).where("NOT message_user_statuses.notified")
                                 .where("message_user_statuses.user_id = ?", user_id)
  end

  def self.all_unnotified_messages_ids_per_user_per_room
    ActiveRecord::Base.connection.execute("
      SELECT platform_id,
             user_id,
             room_id,
             STRING_AGG(message_id::text, ',') AS message_ids
      FROM (
        SELECT u.platform_id,
               u.id AS user_id,
               m.room_id AS room_id,
               m.id AS message_id,
               (ABS(EXTRACT(EPOCH FROM(m.created_at - current_timestamp))))::int AS created_till_seconds
        FROM users u
        JOIN message_user_statuses s ON s.user_id=u.id
        JOIN messages m ON s.message_id=m.id
        WHERE u.id <> m.sender_id
              AND NOT s.read
              AND NOT s.notified
              AND NOT EXISTS (SELECT 1
                              FROM messages
                              WHERE (ABS(EXTRACT(EPOCH FROM(m.created_at - current_timestamp))))::int <= 30
                              AND room_id=m.room_id)
      ) unread_messages
      WHERE created_till_seconds > 30
      GROUP BY 1, 2, 3
    ").inject([]) do | unnotified, result |
      unnotified.push(OpenStruct.new({
        platform_id: result["platform_id"],
        user_id:     result["user_id"],
        room_id:     result["room_id"],
        message_ids: result["message_ids"].split(",")
      }))
      unnotified
    end
  end

  def self.previous_messages_for_room(room, limit, message = nil)
    if message
      sql = "SELECT * FROM (SELECT * FROM messages WHERE room_id = ? AND sequence_number < ?
             ORDER BY sequence_number DESC LIMIT ?) AS foo ORDER BY sequence_number ASC;"
      find_by_sql([sql, room.id, message.sequence_number, limit])
    else
      sql = "SELECT * FROM (SELECT * FROM messages WHERE room_id = ?
            ORDER BY sequence_number DESC LIMIT ?) AS foo ORDER BY sequence_number ASC;"
      find_by_sql([sql, room.id, limit])
    end
  end

  def platform_id
    room.platform_id
  end

  def content=(value)
    super(value.nil? ? nil : CGI::escapeHTML(value))
  end
end
