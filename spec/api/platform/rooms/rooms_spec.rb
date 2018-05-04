require "rails_helper"

RSpec.describe "platform", :platform do
  let(:base_url) { "/platform/rooms" }

  describe "GET rooms" do
    context "when there are no rooms" do
      it "returns a 200" do
        get(base_url, headers: $headers)
        expect(response).to have_http_status(:ok)
      end

      it "returns a room count of 0" do
        get(base_url, headers: $headers)
        expect(json["meta"]["count"]).to eq(0)
      end

      it "returns an empty room list" do
        get(base_url, headers: $headers)
        expect(json["data"].size).to eq(0)
      end
    end

    context "when there are 40 rooms" do
      before do
        1.upto(40) do
          RoomFactory.build_from_server($platform, {}).save!
        end
      end

      it "returns a 200" do
        get(base_url, headers: $headers)
        expect(response).to have_http_status(:ok)
      end

      it "returns a room count of 40" do
        get(base_url, headers: $headers)
        expect(json["meta"]["count"]).to eq(40)
      end

      it "returns a list with the most recently active rooms" do
        get(base_url, headers: $headers)
        expect(json["data"].size).to eq(Room::PER_PAGE)
      end

      context "and I ask for previous active rooms" do
        it "returns exactly the next batch of previous recently active rooms" do
          params             = { per_page: Room::PER_PAGE * 2}
          get(base_url, params: params, headers: $headers)
          all_rooms          = json["data"]

          get(base_url, headers: $headers)
          most_active_rooms  = json["data"]
          first_seen_room_id = most_active_rooms.last["id"]

          params             = { first_seen_room_id: first_seen_room_id }
          get(base_url, params: params, headers: $headers)
          last_active_rooms  = json["data"]

          expect(most_active_rooms + last_active_rooms).to eq(all_rooms)
        end
      end

      context "and I ask for the first 10 rooms" do
        it "returns a list with the first 10 rooms" do
          params = { per_page: 10 }
          get(base_url, params: params, headers: $headers)
          expect(json["data"].size).to eq(10)
        end
      end

      context "and I ask for the previous 10 rooms" do
        let(:per_page) { 10 }

        it "returns exactly the next 10 previous recently active rooms" do
          params             = { per_page: per_page * 2 }
          get(base_url, params: params, headers: $headers)
          all_rooms          = json["data"]

          params             = { per_page: per_page }
          get(base_url, params: params, headers: $headers)
          most_active_rooms  = json["data"]
          first_seen_room_id = most_active_rooms.last["id"]

          params             = { per_page: per_page, first_seen_room_id: first_seen_room_id }
          get(base_url, params: params, headers: $headers)
          last_active_rooms  = json["data"]

          expect(most_active_rooms + last_active_rooms).to eq(all_rooms)
        end

        context "and there are rooms in other platforms" do
          xit "returns only the rooms of my platform"
        end
      end

      context "and I ask for specific rooms that all exist" do
        let(:room_ids) { Room.all.sample(5).map(&:public_id) }

        it "returns a 200" do
          params = room_ids.to_query("room_ids")
          get(base_url, params: params, headers: $headers)
          expect(response).to have_http_status(:ok)
        end

        it "returns only the specified rooms" do
          params = room_ids.to_query("room_ids")
          get(base_url, params: params, headers: $headers)
          response_room_ids = json["data"].map{ |room| room["id"] }
          expect(response_room_ids.sort).to eq(room_ids.sort)
        end
      end

      context "and I ask for specific rooms where at least one does not exist" do
        let(:inexistant_id)       { SecureRandom.uuid }
        let(:other_inexistant_id) { SecureRandom.uuid }
        let(:room_ids)      { Room.all.sample(5).map(&:public_id).push(inexistant_id) }
        let(:more_room_ids) { room_ids.push(other_inexistant_id) }

        it "returns a 404" do
          params = room_ids.to_query("room_ids")
          get(base_url, params: params, headers: $headers)
          expect(response).to have_http_status(:not_found)
        end

        it "tells me which room id could not be found" do
          params = room_ids.to_query("room_ids")
          get(base_url, params: params, headers: $headers)
          errors = json["errors"]
          expect(errors.first["code"]).to match("not_found")
        end

        it "returns an error message per not found id" do
          params = more_room_ids.to_query("room_ids")
          get(base_url, params: params, headers: $headers)
          errors = json["errors"]
          expect(errors.size).to eq(2)
        end
      end
    end
  end

  describe "GET rooms/:id" do
    context "when called with a non-existing room id" do
      let(:room_id) { SecureRandom.uuid }

      it "returns a 404" do
        url = "#{base_url}/#{room_id}"
        get(url, headers: $headers)
        expect(response).to have_http_status(:not_found)
      end

      it "returns a not found error" do
        url = "#{base_url}/#{room_id}"
        get(url, headers: $headers)
        expect(json["errors"].size).to be(1)
      end
    end

    context "when called with a valid room id" do
      let(:room_id) { SecureRandom.uuid }

      before(:each) do
        RoomFactory.build_from_server($platform, data: { id: room_id }).save!
      end

      it "returns a 200"  do
        url = "#{base_url}/#{room_id}"
        get(url, headers: $headers)
        expect(response).to have_http_status(:ok)
      end

      it "return the expected room" do
        url = "#{base_url}/#{room_id}"
        get(url, headers: $headers)
        expect(json["data"]["id"]).to eq(room_id)
      end
    end
  end

  describe "POST rooms" do
    context "when called with an empty parameters hash" do
      it "returns a 201" do
        post(base_url, params: {}.to_json, headers: $headers)
        expect(response).to have_http_status(:created)
      end

      it "returns the new room" do
        post(base_url, params: {}.to_json, headers: $headers)
        expect(json["data"]["id"]).not_to be(nil)
      end
    end

    context "when called with a non-existing room id" do
      let(:room_id) { SecureRandom.uuid }

      it "returns a 201" do
        data = { data: { id: room_id } }
        post(base_url, params: data.to_json, headers: $headers)
        expect(response).to have_http_status(:created)
      end

      it "returns the new room" do
        data = { data: { id: room_id } }
        post(base_url, params: data.to_json, headers: $headers)
        expect(json["data"]["id"]).to eq(room_id)
      end
    end

    context "when called with an existing room id" do
      let(:room_id) { SecureRandom.uuid }

      before(:each) do
        RoomFactory.build_from_server($platform, data: {id: room_id}).save!
      end

      it "returns a 403" do
        data = { data: { id: room_id } }
        post(base_url, params: data.to_json, headers: $headers)
        expect(response).to have_http_status(:forbidden)
      end

      it "returns an error message in the payload" do
        data = { data: { id: room_id } }
        post(base_url, params: data.to_json, headers: $headers)
        expect(json["errors"].size).to be(1)
      end
    end
  end

  describe "PUT rooms" do
    context "when called with an existing room id" do
      let(:room_id) { SecureRandom.uuid }
      let (:new_room_id) { SecureRandom.uuid }

      before(:each) do
        RoomFactory.build_from_server($platform, data: { id: room_id }).save!
      end

      it "returns a 200" do
        url  = "#{base_url}/#{room_id}"
        data = { data: { id: new_room_id } }
        put(url, params: data.to_json, headers: $headers)
        expect(response).to have_http_status(:ok)
      end

      it "returns the new user id" do
        url      = "#{base_url}/#{room_id}"
        data = { data: { id: new_room_id } }
        put(url, params: data.to_json, headers: $headers)
        expect(json["data"]["id"]).to eq(new_room_id)
      end
    end

    context "when called with a non-existing room id" do
      let(:room_id) { SecureRandom.uuid }

      it "returns a 404" do
        url = "#{base_url}/#{room_id}"
        put(url, headers: $headers)
        expect(response).to have_http_status(:not_found)
      end

      it "returns a not found error" do
        url = "#{base_url}/#{room_id}"
        put(url, headers: $headers)
        expect(json["errors"].size).to be(1)
      end
    end
  end

  describe "DELETE rooms" do
    context "when called with no room id" do
      it "returns a 404" do
        delete(base_url, headers: $headers)
        expect(response).to have_http_status(:not_found)
      end

      it "returns a not found error" do
        delete(base_url, headers: $headers)
        expect(json["errors"].size).to be(1)
      end
    end

    context "when called with a non-existing room id" do
      let(:room_id) { SecureRandom.uuid }

      it "returns a 404" do
        url = "#{base_url}/#{room_id}"
        delete(url, headers: $headers)
        expect(response).to have_http_status(:not_found)
      end

      it "returns a not found error" do
        url = "#{base_url}/#{room_id}"
        delete(url, headers: $headers)
        expect(json["errors"].size).to be(1)
      end
    end

    context "when called with a valid room id" do
      let(:room_id) { SecureRandom.uuid }

      before(:each) do
        RoomFactory.build_from_server($platform, data: { id: room_id }).save!
      end

      it "returns a 200"  do
        url = "#{base_url}/#{room_id}"
        delete(url, headers: $headers)
        expect(response).to have_http_status(:ok)
      end

      it "destroys the room in the database" do
        url = "#{base_url}/#{room_id}"
        delete(url, headers: $headers)
        expect($platform.rooms.reload.size).to eq(0)
      end

      it "returns the deleted room" do
        url = "#{base_url}/#{room_id}"
        delete(url, headers: $headers)
        expect(json["data"]["id"]).to eq(room_id)
      end
    end
  end
end
