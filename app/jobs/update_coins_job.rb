class UpdateCoinsJob < ApplicationJob
  queue_as :default

  def perform(exchange_id)
    exchange = Exchange.find(exchange_id)
    exchange.update_coins
  end
end
