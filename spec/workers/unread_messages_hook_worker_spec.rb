require "rails_helper"

RSpec.describe UnreadMessagesHookWorker do
  let(:platform) do
    platform = PlatformFactory.build(data: { attributes: { name: "Flu Test Platform" } })
    platform.offline_user_message_hook_url = "https://example.com/hook"
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

  def stub_faraday_connection
    faraday_request = double("faraday_request", headers: {})
    allow(faraday_request).to receive(:body=)
    connection = double("faraday_connection").as_null_object
    allow(connection).to receive(:post).and_yield(faraday_request)
    allow(Faraday).to receive(:new).and_yield(connection).and_return(connection)
    connection
  end

  it "posts the digest to the platform's webhook url" do
    connection = stub_faraday_connection
    described_class.new.perform(SecureRandom.uuid, recipient.id, [message.id], platform.id)
    expect(connection).to have_received(:post).with(platform.offline_user_message_hook_url)
  end

  it "does not call the webhook when the platform has none configured" do
    platform.update!(offline_user_message_hook_url: nil)
    expect(Faraday).not_to receive(:new)
    described_class.new.perform(SecureRandom.uuid, recipient.id, [message.id], platform.id)
  end
end
