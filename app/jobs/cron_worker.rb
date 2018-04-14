require 'sidekiq-scheduler'

class CronWorker
  include Sidekiq::Worker

  def perform
    b = Binance.last
    Coin.new_candle(b.id, '15m')
    # NewCandleJob.perform_later(b.id.to_s, '15m')
    Coin.new_candle(b.id, '1h') if [0, 1, 2, 3, 4].include? Time.now.min
  end
end
