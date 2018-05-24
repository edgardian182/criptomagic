class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  def btc_alert
    btc = Coin.search('btc')
    candle = btc.candles.where(range: '15m').last
    flag = Flag.where(candle: candle).last
    flag_items = flag.items if flag
    alerts = %w[exit_volume_low exit_volume_get_out exit_volume_price_l3]
    @btc_alert = alerts & flag_items if flag_items
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username name lastname])
  end
end
