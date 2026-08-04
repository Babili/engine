require "rails_helper"

RSpec.describe "flu-rails event tracking" do
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

  def build_room(users: [user])
    room = RoomFactory.build_from_server(platform, {
      data: { relationships: { users: { data: users.map { |u| { id: u.public_id } } } } }
    })
    room.save!
    room
  end

  def build_message(room, sender: user)
    message = MessageFactory.build_from_server(platform, {
      room_id: room.public_id,
      data: { relationships: { user: { data: { id: sender.public_id } } } }
    })
    message.save!
    message
  end

  it "uses the in-memory dummy publisher in the test environment" do
    expect(Flu.event_publisher).to be_a(Flu::Dummy::InMemoryEventPublisher)
  end

  describe "Platform" do
    it "emits an event when a platform is created" do
      expect { platform }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a tracked attribute is updated" do
      platform
      Flu.event_publisher.clear
      platform.update!(name: "Renamed Platform")
      expect(Flu.event_publisher.events_count).to be >= 1
    end

    it "does not emit an event when only ignored (RSA key) attributes change" do
      platform
      Flu.event_publisher.clear
      platform.update!(user_rsa_public: OpenSSL::PKey::RSA.generate(2048).public_key.to_s)
      expect(Flu.event_publisher.events_count).to eq(0)
    end
  end

  describe "User" do
    it "emits an event when a user is created" do
      expect { user }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a user goes online (status update)" do
      user
      Flu.event_publisher.clear
      user.alive!
      expect(Flu.event_publisher.events_count).to be >= 1
    end

    it "emits an event when a user is destroyed" do
      user
      Flu.event_publisher.clear
      user.destroy!
      expect(Flu.event_publisher.events_count).to be >= 1
    end
  end

  describe "Room" do
    it "emits an event when a room is created" do
      user
      Flu.event_publisher.clear
      expect { build_room }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a room is destroyed" do
      room = build_room
      Flu.event_publisher.clear
      room.destroy!
      expect(Flu.event_publisher.events_count).to be >= 1
    end
  end

  describe "Message" do
    it "emits an event when a message is created" do
      room = build_room
      Flu.event_publisher.clear
      expect { build_message(room) }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a message is destroyed" do
      room    = build_room
      message = build_message(room)
      Flu.event_publisher.clear
      message.destroy!
      expect(Flu.event_publisher.events_count).to be >= 1
    end
  end

  describe "Membership" do
    let(:other_user) do
      other_user = UserFactory.build_from_server(platform, {})
      other_user.save!
      other_user
    end

    it "emits an event when a membership is created" do
      room = build_room
      Flu.event_publisher.clear
      membership = MembershipFactory.build_from_server(platform, { room_id: room.public_id, user_id: other_user.public_id })
      expect { membership.save! }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a membership is destroyed" do
      room       = build_room
      membership = MembershipFactory.build_from_server(platform, { room_id: room.public_id, user_id: other_user.public_id })
      membership.save!
      Flu.event_publisher.clear
      membership.destroy!
      expect(Flu.event_publisher.events_count).to be >= 1
    end
  end

  describe "MessageUserStatus" do
    let(:recipient) do
      recipient = UserFactory.build_from_server(platform, {})
      recipient.save!
      recipient
    end

    it "emits an event when a status is created" do
      room = build_room
      Flu.event_publisher.clear
      expect { build_message(room) }.to change { Flu.event_publisher.events_count }.by_at_least(1)
    end

    it "emits an event when a message is marked as read" do
      room    = build_room(users: [user, recipient])
      message = build_message(room, sender: user)
      status  = message.message_user_statuses.find_by!(user_id: recipient.id)
      Flu.event_publisher.clear
      status.mark_as_read
      status.save!
      expect(Flu.event_publisher.events_count).to be >= 1
    end
  end

  describe "EventPublisher (manual events)" do
    it "publishes a manual 'notify offline messages' event" do
      room    = build_room
      message = build_message(room)
      Flu.event_publisher.clear
      EventPublisher.notify_offline_messages(user, [message], room)
      expect(Flu.event_publisher.events_count).to eq(1)
    end

    it "does not publish anything when there are no messages" do
      room = build_room
      Flu.event_publisher.clear
      EventPublisher.notify_offline_messages(user, [], room)
      expect(Flu.event_publisher.events_count).to eq(0)
    end
  end
end
