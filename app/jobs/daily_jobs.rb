require 'sidekiq-scheduler'

class DailyJobs
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    # Search and create new coins
    Exchange.each(&:create_coins)

    # Clear Candles and Analysis
    Candle.where(:open_time.lt => Time.now - 1.week).each(&:destroy)
    AnalyzeResult.where(:close_time.lt => Time.now - 1.week).each(&:destroy)

    # Events
    Event.where(:date_event.lt => Time.now.beginning_of_day).each(&:destroy)
    Coin.new_events_token if Eapp.where(name: 'CriptoMagic').first.events_exp < (Time.now + 2.days)
    Eapp.where(name: 'CriptoMagic').first.update_marketcal_coins
    Coin.all.uniq(&:name).each(&:create_events)
  end
end
