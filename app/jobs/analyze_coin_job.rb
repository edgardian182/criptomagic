class AnalyzeCoinJob < ApplicationJob
  queue_as :default

  def perform(coin_id, periods, range, time = nil)
    coin = Coin.find(coin_id)

    if time
      t = Time.at(time)
      coin.analyze(periods, range, t)
    else
      coin.analyze(periods, range)
    end
  end
end
