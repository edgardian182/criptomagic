class AnalyzeCoinJob < ApplicationJob
  queue_as :default

  def perform(coin_id, periods, range)
    coin = Coin.find(coin_id)
    coin.analyze(periods, range)
  end
end
