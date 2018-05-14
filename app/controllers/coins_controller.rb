class CoinsController < ApplicationController
  def show
    @coin = params[:search] ? Coin.search(params[:search]) : Coin.find(params[:id])
    if @coin
      @exchange = @coin.exchange
      @btc_alert = btc_alert
    else
      @exchange = Exchange.first
      redirect_to exchange_path(@exchange)
    end
  end

  def analyze
    periods = params[:periods].to_i
    range = params[:range]

    year = params['date']['year']
    month = params['date']['month']
    day = params['date']['day']
    hour = params['date']['hour']
    minute = params['date']['minute']

    time = Time.local(year, month, day, hour, minute)
    coin = Coin.find(params[:coin_id])

    AnalyzeCoinJob.perform_later(coin.id.to_s, periods, range, time.to_i)

    redirect_to coin_path(coin, analysis: { periods: periods, range: range, time: time.to_i, year: year, month: month, day: day, hour: hour, minute: minute })
  end
end
