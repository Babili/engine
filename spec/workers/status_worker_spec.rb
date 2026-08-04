require "rails_helper"

RSpec.describe StatusWorker do
  let(:platform) do
    platform = PlatformFactory.build(data: { attributes: { name: "Flu Test Platform" } })
    platform.save!
    platform
  end

  def build_user(alive_at:, status:)
    user = UserFactory.build_from_server(platform, {})
    user.alive_at = alive_at
    user.status   = status
    user.save!
    user
  end

  it "sets users inactive for more than a minute to offline" do
    user = build_user(alive_at: 2.minutes.ago, status: "online")
    described_class.new.perform
    expect(user.reload.status).to eq("offline")
  end

  it "sets users with no alive_at at all to offline" do
    user = build_user(alive_at: nil, status: "online")
    described_class.new.perform
    expect(user.reload.status).to eq("offline")
  end

  it "leaves recently active users untouched" do
    user = build_user(alive_at: 10.seconds.ago, status: "online")
    described_class.new.perform
    expect(user.reload.status).to eq("online")
  end

  it "emits a flu update event when a user transitions to offline" do
    build_user(alive_at: 2.minutes.ago, status: "online")
    Flu.event_publisher.clear
    described_class.new.perform
    expect(Flu.event_publisher.events_count).to be >= 1
  end
end
