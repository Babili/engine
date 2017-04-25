class User::RoomPresenter < BasePresenter
  def self.map(rooms:, messages_per_room:, room_count:, current_user:)
    array = rooms.map do |room|
      new(room: room, messages_per_room: messages_per_room, current_user: current_user).data
    end

    {
      data: array,
      meta: {
        count: room_count
      }
    }
  end

  def initialize(room:,messages_per_room:, current_user:, first_seen_message: nil)
    @room               = room
    @messages_per_room  = messages_per_room
    @current_user       = current_user
    @first_seen_message = first_seen_message
  end

  def data
    result = {
      type:       "room",
      id:         @room.public_id,
      attributes: {
        name:               @room.name,
        unreadMessageCount: @room.unread_message_count_for_user(@current_user),
        open:               @room.open_for_user(@current_user),
        lastActivityAt:     @room.last_activity_at
      },
      relationships: {
        messages: User::MessagePresenter.map(
          messages:       @room.messages_before(@messages_per_room, @first_seen_message),
          room_public_id: @room.public_id
        ),
        users:    User::UserPresenter.map(@room.users),
        senders:  User::UserPresenter.map(@room.senders)
      }
    }
    result[:relationships][:initiator] =  User::UserPresenter.new(@room.initiator).data if @room.initiator
    result
  end
end
