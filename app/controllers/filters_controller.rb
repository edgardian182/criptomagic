class FiltersController < ApplicationController
  def index
    @tab = :filters
    @btc_alert = btc_alert
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

    AnalyzeFilterJob.perform_later(exchange.id.to_s, periods, range, filter, time.to_i)
    # exchange.analyze_coins(range, filter, time)

    redirect_to filters_path(analysis: { exchange: exchange, filter: filter, periods: periods, range: range, time: time.to_i, year: year, month: month, day: day, hour: hour, minute: minute })
  end
end
