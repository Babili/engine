require "rails_helper"

RSpec.describe "platform", :platform do
  let(:base_url) { "/platform/rooms/:roomId/messages" }
  describe "rooms" do
    let(:room_id) { SecureRandom.uuid }
    let(:url)     { base_url.gsub(":roomId", room_id) }

    before(:each) do
      @room = RoomFactory.build_from_server($platform, data: { id: room_id })
      @room.save!
    end

    describe "POST messages" do
      context "when called with an empty parameters hash" do
        it "returns a 201" do
          post(url, params: {}.to_json, headers: $headers)
          expect(response).to have_http_status(:created)
        end

        it "returns the new message" do
          post(url, params: {}.to_json, headers: $headers)
          expect(json["data"]["id"]).not_to be(nil)
        end

        it "updates the last_activity_at attribute of the room to the current time" do
          past_time = Time.zone.now - 2.hours
          @room.update(last_activity_at: past_time)
          post(url, params: {}.to_json, headers: $headers)
          expect(@room.reload.last_activity_at).to be > past_time
        end
      end

      context "when called with a non-existing message id" do
        let(:message_id) { SecureRandom.uuid }

        it "returns a 201" do
          data = { data: { id: message_id } }
          post(url, params: data.to_json, headers: $headers)
          expect(response).to have_http_status(:created)
        end

        it "returns the new message" do
          data = { data: { id: message_id } }
          post(url, params: data.to_json, headers: $headers)
          expect(json["data"]["id"]).to eq(message_id)
        end
      end

      context "when called with an existing message id" do
        let(:message_id) { SecureRandom.uuid }

        before(:each) do
          MessageFactory.build_from_server($platform, room_id: room_id, data: { id: message_id }).save!
        end

        it "returns a 403" do
          data = { data: { id: message_id } }
          post(url, params: data.to_json, headers: $headers)
          expect(response).to have_http_status(:forbidden)
        end

        it "returns an error message in the payload" do
          data = { data: { id: message_id } }
          post(url, params: data.to_json, headers: $headers)
          expect(json["errors"].size).to be(1)
        end
      end

      context "when called with a message containing HTML" do
        let(:corrupted_content) { "<script>Hello</script>" }

        it "returns a 201" do
          post(url, params: { data: { attributes: { content: corrupted_content } } }.to_json, headers: $headers)
          expect(response).to have_http_status(:created)
        end

        it "returns the new message with HTML escaped" do
          post(url, params: { data: { attributes: { content: corrupted_content } } }.to_json, headers: $headers)
          expect(json.dig("data", "attributes", "content")).to eq "&lt;script&gt;Hello&lt;/script&gt;"
        end
      end
    end

    describe "DELETE messages" do
      context "when called with no message id" do
        it "returns a 404" do
          delete(url, headers: $headers)
          expect(response).to have_http_status(:not_found)
        end

        it "returns a not found error" do
          delete(url, headers: $headers)
          expect(json["errors"].size).to be(1)
        end
      end

      context "when called with a non-existing message id" do
        let(:message_id) { SecureRandom.uuid }

        it "returns a 404" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect(response).to have_http_status(:not_found)
        end

        it "returns a not found error" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect(json["errors"].size).to be(1)
        end
      end

      context "when called with a valid message id" do
        let(:message_id) { SecureRandom.uuid }

        before(:each) do
          MessageFactory.build_from_server($platform, room_id: room_id, data: { id: message_id }).save!
        end

        it "returns a 200"  do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect(response).to have_http_status(:ok)
        end

        it "destroys the message in the database" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect($platform.messages.reload.size).to eq(0)
        end

        it "returns the deleted message" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect(json["data"]["id"]).to eq(message_id)
        end
      end
    end
  end
end
