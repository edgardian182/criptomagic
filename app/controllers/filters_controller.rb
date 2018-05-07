class FiltersController < ApplicationController
  def index
    @tab = :filters
  end

  def analyze
    exchange = Exchange.where(name: params[:exchange]).first
    filter = params[:filter]

    periods = params[:periods].to_i
    range = params[:range]

    year = params['date']['year']
    month = params['date']['month']
    day = params['date']['day']
    hour = params['date']['hour']
    minute = params['date']['minute']

    time = Time.local(year, month, day, hour, minute)

    # AnalyzeCoinJob.perform_later(coin.id.to_s, periods, range, time.to_i)
    exchange.analyze_coins(range, filter, time)

    redirect_to filters_path(analysis: { exchange: exchange, filter: filter, periods: periods, range: range, time: time.to_i })
  end
end
