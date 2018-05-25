class ClearCandlesJob < ApplicationJob
  queue_as :low

  def perform
    Candle.where(:open_time.lt => Time.now - 1.week).each(&:destroy)
  end
end
