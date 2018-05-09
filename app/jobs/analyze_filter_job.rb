class AnalyzeFilterJob < ApplicationJob
  queue_as :default

  def perform(exchange_id, periods, range, filter, time = nil)
    exchange = Exchange.find(exchange_id)

    if time
      t = Time.at(time)
      exchange.analyze_coins(range, filter, t)
    else
      exchange.analyze_coins(range, filter)
    end
  end
end
