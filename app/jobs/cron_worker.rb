require 'sidekiq-scheduler'

class CronWorker
  include Sidekiq::Worker

  def perform
    Exchange.each do |exchange|
      Coin.new_candle(exchange.id)

      UpdateCoinsJob.perform_later(exchange.id.to_s) if Time.now.min % 7 == 0
    end
  end
end
