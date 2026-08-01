class UnreadMessagesHookWorker
  include Sidekiq::Worker

  def perform(digest_id, recipient_id, message_ids, platform_id)
    @digest_id = digest_id
    @messages  = Message.where(id: message_ids)
    @platform  = Platform.find(platform_id)
    @recipient = User.find(recipient_id)
    @room      = @messages.first.room
    if @messages.any? && @platform.has_offline_message_hook?
      connection.post(@platform.offline_user_message_hook_url) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept']       = 'application/json'
        req.body                    = build_body.to_json
      end
    end
  end

  private

  def connection
    Faraday.new do |conn|
      conn.response :raise_error
      conn.adapter Faraday.default_adapter
    end
  end

  def build_body
    body = {
      type: "unread_messages_digest",
      id: @digest_id,
      relationships: {
        recipient: {
          data: {
            type: :user,
            id:   @recipient.public_id
          }
        },
        messages: {
          data: @messages.map { |message| create_body_for_message(message)}
        },
        room: {
          data: {
            type: :room,
            id:   @room.public_id,
            name: @room.name
          }
        }
      }
    }
  end

  def create_body_for_message(message)
    body = {
      type:       "message",
      id:         message.public_id,
      attributes: {
        content:     message.content,
        contentType: message.content_type,
        createdAt:   message.created_at
      },
      relationships: {
        room: {
          data: {
            type: "room",
            id:   @room.public_id
          }
        }
      }
    }

    if message.sender
      body[:relationships][:sender] = {
        data: {
          type: "user",
          id:   message.sender.public_id
        }
      }
    end

    body
  end
end
