class NewCandleJob < ApplicationJob
  require 'future'

  queue_as :critical

  def perform(exchange_id, range)
    exchange = Exchange.find(exchange_id)

    Coin.where(exchange: exchange).each do |c|
      future { c.create_candlestick(range) }
    end
  end
end
