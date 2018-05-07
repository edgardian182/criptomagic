class UpdateCoinsJob < ApplicationJob
  queue_as :default

  def perform(exchange_id)
    exchange = Exchange.find(exchange_id)
    exchange.update_coins
    exchange.update_coins_24h_volume
  end
end
