class NewCandleJob < ApplicationJob
  require 'future'

  queue_as :default

  def perform(exchange_id, range)
    exchange = Exchange.find(exchange_id)

    # coins_c = exchange.coins.count
    # candles_c = exchange.candles.where(range: range).count
    # count = coins_c + candles_c
    create_candles(exchange, range)
  end

  def create_candles(exchange, range)
    Coin.where(exchange: exchange).each do |c|
      future { c.create_candlestick(range) }
    end
  end
end
