class GenerateCandleJob < ApplicationJob
  queue_as :default

  def perform(coin_id, range)
    coin = Coin.find(coin_id)
    coin.create_candlestick(range)
  end
end
