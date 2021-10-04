require "rails_helper"

RSpec.describe "user", :user do
  let(:base_url) { "/user/rooms/:roomId/messages" }
  describe "rooms" do
    let(:room_id) { SecureRandom.uuid }
    let(:url)     { base_url.gsub(":roomId", room_id) }

    before(:each) do
      @room = RoomFactory.build_from_server($platform, data: { id: room_id })
      @room.save!
      MembershipFactory.build_from_server($platform, { room_id: @room.public_id, user_id: $user.public_id }).save!
    end

    describe "GET messages" do
      context "when there are no messages" do
        it "returns a 200" do
          get(url, headers: $headers)
          expect(response).to have_http_status(:ok)
        end

        it "returns a message count of 0" do
          get(url, headers: $headers)
          expect(json["meta"]["count"]).to eq(0)
        end

        it "returns an empty message list" do
          get(url, headers: $headers)
          expect(json["data"].size).to eq(0)
        end
      end

      context "when there are 40 messages" do
        before do
          1.upto(40) do
            MessageFactory.build_from_server($platform, {
              room_id: @room.public_id,
              data: {
                attributes: {
                  content: "My message"
                }
              }
            }).save!
          end
        end

        it "returns a 200" do
          get(url, headers: $headers)
          expect(response).to have_http_status(:ok)
        end

        it "returns a message count of 40" do
          get(url, headers: $headers)
          expect(json["meta"]["count"]).to eq(40)
        end

        it "returns a list with the most recent messages" do
          get(url, headers: $headers)
          expect(json["data"].size).to eq(Message::PER_PAGE)
        end

        context "and I ask for previous messages" do
          it "returns exactly the next batch of previous messages" do
            params                = { per_page: Message::PER_PAGE * 2 }
            get(url, params: params, headers: $headers)
            all_messages          = json["data"]

            get(url, headers: $headers)
            most_recent_messages  = json["data"]

            first_seen_message_id = most_recent_messages.first["id"]
            params                = { first_seen_message_id: first_seen_message_id }
            get(url, params: params, headers: $headers)
            previous_messages     = json["data"]

            expect(previous_messages + most_recent_messages).to eq(all_messages)
          end
        end

        context "and I ask for the first 10 messages" do
          it "returns a list with the first 10 messages" do
            params = { per_page: 10 }
            get(url, params: params, headers: $headers)
            expect(json["data"].size).to eq(10)
          end
        end

        context "and I ask for the previous 10 messages" do
          let(:per_page) { 10 }

          it "returns exactly the next 10 previous recently active messages" do
            params                = { per_page: per_page * 2 }
            get(url, params: params, headers: $headers)
            all_messages          = json["data"]

            params                = { per_page: per_page }
            get(url, params: params, headers: $headers)
            most_recent_messages  = json["data"]
            first_seen_message_id = most_recent_messages.first["id"]

            params                = { per_page: per_page, first_seen_message_id: first_seen_message_id }
            get(url, params: params, headers: $headers)
            previous_messages     = json["data"]

            expect(previous_messages + most_recent_messages).to eq(all_messages)
          end
        end
      end

      context "and there are messages in other rooms" do
        before do
          room = RoomFactory.build_from_server($platform, {})
          room.save!
          MembershipFactory.build_from_server($platform, { room_id: room.public_id, user_id: $user.public_id }).save!
          @message = MessageFactory.build_from_server($platform,
            room_id: room.public_id,
            data: {
              attributes: {
                content: "Other message"
              }
            }
          )
          @message.save!
        end

        it "returns only the messages of my room" do
          second_message = MessageFactory.build_from_server($platform,
            room_id: @room.public_id,
            data: {
              attributes: {
                content: "Other message"
              }
            }
          )
          second_message.save!
          get(url, headers: $headers)
          expect(json["data"].map { |m| m["id"] }.include?(@message.public_id)).to be false
          expect(json["data"].map { |m| m["id"] }.include?(second_message.public_id)).to be true
        end
      end
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
          @room.update({ last_activity_at: past_time })
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
          MessageFactory.build_from_server($platform,
            room_id: room_id,
            data: {
              id: message_id,
              relationships: {
                user: {
                  data: {
                    id: $user.public_id
                  }
                }
              }
            }
          ).save!
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
          message = MessageFactory.build_from_server($platform,
            room_id: room_id,
            data: {
              id: message_id,
              relationships: {
                user: {
                  data: {
                    id: $user.public_id
                  }
                }
              }

            }
          )
          message.save!
        end

        it "returns a 200" do
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

      context "when called with a message id that doesn't belong to current user" do
        let(:message_id) { SecureRandom.uuid }

        before(:each) do
          message = MessageFactory.build_from_server($platform,
            room_id: room_id,
            data: {
              id: message_id
            }
          )
          message.save!
        end

        it "returns a 404" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect(response).to have_http_status(:not_found)
        end

        it "should not destroy the message in the database" do
          delete_url = "#{url}/#{message_id}"
          delete(delete_url, headers: $headers)
          expect($platform.messages.reload.size).to eq(1)
        end
      end
    end
  end
end
