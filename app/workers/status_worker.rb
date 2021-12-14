class StatusWorker
  include Sidekiq::Worker

  def perform
    query = "(alive_at < ? OR alive_at IS NULL) AND status != 'offline'"
    User.where(query, Time.zone.now - 1.minute).each do |user|
      Rails.logger.info "Set status to offline for #{user.id}"
      user.status = :offline
      user.save!
    end
  end
end
