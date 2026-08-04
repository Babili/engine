require "rails_helper"

RSpec.describe UnreadMessagesNotificationWorker do
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

  let(:message) do
    message = MessageFactory.build_from_server(platform, {
      room_id: room.public_id,
      data: { relationships: { user: { data: { id: sender.public_id } } } }
    })
    message.save!
    message
  end

  it "marks the message as notified for the recipient" do
    described_class.new.perform(platform.id, recipient.id, room.id, [message.id])
    expect(message.has_been_notified_to?(recipient.id)).to be(true)
  end

  it "does not call the platform's offline hook when none is configured" do
    expect(UnreadMessagesHookWorker).not_to receive(:perform_async)
    described_class.new.perform(platform.id, recipient.id, room.id, [message.id])
  end

  it "calls the platform's offline hook when one is configured" do
    platform.update!(offline_user_message_hook_url: "https://example.com/hook")
    expect(UnreadMessagesHookWorker).to receive(:perform_async)
      .with(kind_of(String), recipient.id, [message.id], platform.id)
    described_class.new.perform(platform.id, recipient.id, room.id, [message.id])
  end

  it "emits a flu manual event for the offline notification" do
    Flu.event_publisher.clear
    described_class.new.perform(platform.id, recipient.id, room.id, [message.id])
    expect(Flu.event_publisher.events_count).to be >= 1
  end

  it "does nothing when the messages are already notified" do
    MessageUserStatus.mark_as_notified(recipient.id, message.id)
    Flu.event_publisher.clear
    described_class.new.perform(platform.id, recipient.id, room.id, [message.id])
    expect(Flu.event_publisher.events_count).to eq(0)
  end
end
