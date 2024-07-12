class DeleteMessagesAndRoomsWorker
  include Sidekiq::Worker

  def perform(before_date)
    Message.transaction do
      Message.created_before(before_date).each(&:destroy!)
      Room.without_any_message.each(&:destroy!)
    end
  end
end
