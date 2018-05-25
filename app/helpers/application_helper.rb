module ApplicationHelper
  def btc_alert
    btc = Coin.search('btc')
    candle = btc.candles.where(range: '15m').last
    flag = Flag.where(candle: candle).last
    flag_items = flag.items if flag
    alerts = %w[exit_volume_low exit_volume_get_out exit_volume_price_l3]
    @btc_alert = alerts & flag_items if flag_items
  end

  def bootstrap_class_for(flash_type)
    {
      success: "alert-success",
      error: "alert-danger",
      notice: "alert-info",
      warning: "alert-warning",
      alert: "alert-danger"
    }[flash_type.to_sym] || flash_type.to_s
  end

  def bootstrap_glyphs_icon(flash_type)
    {
      success: "glyphicon-ok",
      error: "glyphicon-exclamation-sign",
      notice: "glyphicon-info-sign",
      warning: "glyphicon-warning-sign",
      alert: "alert-danger"
    }[flash_type.to_sym] || 'glyphicon-screenshot'
  end
end
