class Internal::MessageDeletionsController < InternalController
  def create
    before_date = params[:before_date]&.to_date
    if before_date.present?
      DeleteMessagesAndRoomsWorker.perform_async(before_date.iso8601)
      render head: true, status: :accepted
    else
      render json: { reason: :no_date_provided }, status: :bad_request
    end
  end
end
