require 'sidekiq-scheduler'

class DailyJobs
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    ClearCandlesJob.perform_later
    Exchange.each do |exchange|
      CreateCoinsJob.perform_later(exchange.id.to_s)
    end
  end
end
