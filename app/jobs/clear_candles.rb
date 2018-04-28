require 'sidekiq-scheduler'

class ClearCandles
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    Candle.where(:open_time.lt => Time.now - 2.week).each(&:destroy)
  end
end
