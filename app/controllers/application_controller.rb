class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def btc_alert
    btc = Coin.search('btc')
    candle = btc.candles.where(range: '15m').last
    flag = Flag.where(candle: candle).last
    flag_items = flag.items if flag
    alerts = %w[exit_volume_low exit_volume_get_out exit_volume_price_l3]
    @btc_alert = alerts & flag_items if flag_items
  end
end
