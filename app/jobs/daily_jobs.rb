require 'sidekiq-scheduler'

class DailyJobs
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    # Search and create new coins
    Exchange.each(&:create_coins)

    # Clear Candles and Analysis
    Candle.where(:open_time.lt => Time.now - 1.week).each(&:destroy)
    AnalyzeResult.where(:close_time.lt => Time.now - 1.week).each(&:destroy)
  end
end
