require 'sidekiq-scheduler'

class CronWorker
  include Sidekiq::Worker

  def perform
    Exchange.each do |exchange|
      Coin.new_candle(exchange.id, '15m')
      Coin.new_candle(exchange.id, '30m')
      # NewCandleJob.perform_later(b.id.to_s, '15m')
      Coin.new_candle(exchange.id, '1h')

      UpdateCoinsJob.perform_later(exchange.id.to_s) if Time.now.min % 5 == 0
    end
  end
end
