class CreateCoinsJob < ApplicationJob
  queue_as :default

  def perform(exchange_id)
    exchange = Exchange.find(exchange_id)
    exchange.create_coins
  end
end
