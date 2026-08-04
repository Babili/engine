require "rails_helper"

RSpec.describe DeleteMessagesAndRoomsWorker do
  let(:platform) do
    platform = PlatformFactory.build(data: { attributes: { name: "Flu Test Platform" } })
    platform.save!
    platform
  end

  let(:user) do
    user = UserFactory.build_from_server(platform, {})
    user.save!
    user
  end

  def build_room_with_message(created_at:)
    room = RoomFactory.build_from_server(platform, {
      data: { relationships: { users: { data: [{ id: user.public_id }] } } }
    })
    room.save!
    message = MessageFactory.build_from_server(platform, {
      room_id: room.public_id,
      data: { relationships: { user: { data: { id: user.public_id } } } }
    })
    message.created_at = created_at
    message.save!
    room
  end

  def build_empty_room
    room = RoomFactory.build_from_server(platform, {})
    room.save!
    room
  end

  it "destroys messages created before the given date" do
    room    = build_room_with_message(created_at: 40.days.ago)
    message = room.messages.first
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Message.exists?(message.id)).to be(false)
  end

  it "keeps messages created after the given date" do
    room    = build_room_with_message(created_at: 5.days.ago)
    message = room.messages.first
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Message.exists?(message.id)).to be(true)
  end

  it "destroys rooms left without any message after old messages are purged" do
    room = build_room_with_message(created_at: 40.days.ago)
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Room.exists?(room.id)).to be(false)
  end

  it "keeps rooms that still have messages" do
    room = build_room_with_message(created_at: 5.days.ago)
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Room.exists?(room.id)).to be(true)
  end

  it "destroys any room without messages, regardless of the room's own age" do
    room = build_empty_room
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Room.exists?(room.id)).to be(false)
  end

  it "emits flu destroy events for the purged messages and rooms" do
    build_room_with_message(created_at: 40.days.ago)
    Flu.event_publisher.clear
    described_class.new.perform(30.days.ago.to_date.iso8601)
    expect(Flu.event_publisher.events_count).to be >= 2
  end
end
