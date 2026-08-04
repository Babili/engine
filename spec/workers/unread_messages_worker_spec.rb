require "rails_helper"

RSpec.describe UnreadMessagesWorker do
  let(:platform) do
    platform = PlatformFactory.build(data: { attributes: { name: "Flu Test Platform" } })
    platform.save!
    platform
  end

  let(:sender) do
    sender = UserFactory.build_from_server(platform, {})
    sender.save!
    sender
  end

  let(:recipient) do
    recipient = UserFactory.build_from_server(platform, {})
    recipient.save!
    recipient
  end

  let(:room) do
    room = RoomFactory.build_from_server(platform, {
      data: { relationships: { users: { data: [{ id: sender.public_id }, { id: recipient.public_id }] } } }
    })
    room.save!
    room
  end

  def send_message(created_at:)
    message = MessageFactory.build_from_server(platform, {
      room_id: room.public_id,
      data: { relationships: { user: { data: { id: sender.public_id } } } }
    })
    message.created_at = created_at
    message.save!
    message
  end

  it "queues a notification worker for a recipient with an unread message older than 30 seconds" do
    message = send_message(created_at: 40.seconds.ago)
    allow(UnreadMessagesNotificationWorker).to receive(:perform_async)
    described_class.new.perform
    expect(UnreadMessagesNotificationWorker).to have_received(:perform_async)
      .with(platform.id, recipient.id, room.id, [message.id])
  end

  it "does not queue anything for messages sent less than 30 seconds ago" do
    send_message(created_at: 5.seconds.ago)
    allow(UnreadMessagesNotificationWorker).to receive(:perform_async)
    described_class.new.perform
    expect(UnreadMessagesNotificationWorker).not_to have_received(:perform_async)
  end

  it "does not queue anything once the recipient has already read the message" do
    message = send_message(created_at: 40.seconds.ago)
    MessageUserStatus.mark_as_read(recipient.id, message.id)
    allow(UnreadMessagesNotificationWorker).to receive(:perform_async)
    described_class.new.perform
    expect(UnreadMessagesNotificationWorker).not_to have_received(:perform_async)
  end
end
