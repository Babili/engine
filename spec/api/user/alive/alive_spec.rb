require "rails_helper"

RSpec.describe "user", :user do
  let(:base_url) { "/user/alive" }

  describe "PUT /alive" do

    it "returns a 200" do
      put(base_url, headers: $headers)
      expect(response).to have_http_status(:ok)
    end

    it "updates the alive_at attribute of the user" do
      past_time = Time.zone.now - 2.hours
      $user.update({ alive_at: past_time })
      put(base_url, headers: $headers)
      expect($user.reload.alive_at).to be > past_time
    end

    it "sets the user status to online" do
      $user.update({ status: "offline" })
      put(base_url, headers: $headers)
      expect($user.reload.status).to eq("online")
    end
  end
end
