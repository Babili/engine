require "rails_helper"

RSpec.describe "internal", :internal do
  let(:base_url) { "/internal/message-deletions" }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /message-deletions" do
    context "when a before_date is provided" do
      let(:before_date) { "2020-01-01" }

      it "returns a 202" do
        allow(DeleteMessagesAndRoomsWorker).to receive(:perform_async)
        post(base_url, params: { before_date: before_date }.to_json, headers: json_headers)
        expect(response).to have_http_status(:accepted)
      end

      it "queues a delete messages and rooms worker with the given date" do
        allow(DeleteMessagesAndRoomsWorker).to receive(:perform_async)
        post(base_url, params: { before_date: before_date }.to_json, headers: json_headers)
        expect(DeleteMessagesAndRoomsWorker).to have_received(:perform_async).with(Date.parse(before_date).iso8601)
      end
    end

    context "when no before_date is provided" do
      it "returns a 400" do
        allow(DeleteMessagesAndRoomsWorker).to receive(:perform_async)
        post(base_url, params: {}.to_json, headers: json_headers)
        expect(response).to have_http_status(:bad_request)
      end

      it "does not queue a worker" do
        allow(DeleteMessagesAndRoomsWorker).to receive(:perform_async)
        post(base_url, params: {}.to_json, headers: json_headers)
        expect(DeleteMessagesAndRoomsWorker).not_to have_received(:perform_async)
      end

      it "returns the no_date_provided reason" do
        post(base_url, params: {}.to_json, headers: json_headers)
        expect(json["reason"]).to eq("no_date_provided")
      end
    end
  end
end
