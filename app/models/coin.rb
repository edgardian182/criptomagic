class Coin
  include Mongoid::Document
  include Mongoid::Timestamps
  include TimeHandler
  extend TimeHandler

  # - fields -
  field :name, type: String
  field :symbol, type: String
  field :rank, type: Integer
  field :price_usd, type: Float
  field :price_btc, type: Float
  field :volume_24h_usd, type: Float
  field :market_cap_usd, type: Float
  field :available_supply, type: Float
  field :total_supply, type: Float
  field :max_supply, type: Float
  field :percent_change_1h, type: Float
  field :percent_change_24h, type: Float
  field :percent_change_7d, type: Float
  field :last_updated, type: Integer # Pasar a int y luego Time.at()

  # - relationships -
  has_many :candles, dependent: :destroy
  belongs_to :exchange

  # - validations -
  validates_presence_of :symbol
  validate :exchange_uniqueness, on: :create

  def last_updated
    Time.at(self[:last_updated])
  end

  def self.total_supply(supply)
    Coin.where(:total_supply.lte => supply).to_a
  end

  def price
    exchange.price_for(symbol)
  end

  def update_coin
    coin = exchange.market.coin_info(symbol)
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
    coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'

    update(coin)
  end

  def change
    {
      price_usd: price_usd,
      price_btc: price_btc,
      one_hour: "#{percent_change_1h}%",
      one_day: "#{percent_change_24h}%",
      seven_days: "#{percent_change_7d}%",
      last_updated: last_updated
    }
  end

  def self.search(symbol)
    Coin.where(symbol: symbol.upcase).first
  end

  # Mas rapido que generate_candle
  def self.new_candle(exchange_id, range = '15m', time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)
    t0 = time - mins.minutes

    exchange = Exchange.find(exchange_id)
    total_coins = exchange.coins.count
    last_candles = Candle.where(range: range, open_time: t0, exchange: exchange).count

    NewCandleJob.perform_later(exchange_id.to_s, range) if total_coins != last_candles
  end

  def self.generate_candle(exchange_id, range = '15m')
    Coin.where(exchange: exchange_id).each do |coin|
      GenerateCandleJob.perform_later(coin.id.to_s, range)
    end
  end

  def analyze_coin(periods, range)
    AnalyzeCoinJob.perform_later(id.to_s, periods, range)
  end

  # Puede usarse para create_candles para mas temporalidades (1h, 4h, 1d, 1w, 1M)
  def create_candlestick(range = '15m', time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)
    mins = INTERVALS[range]

    t0 = time - mins.minutes
    return logger.info 'Candle already exists' if candles.where(range: range, open_time: t0).exists?

    candles_info = exchange.last_candlestick_for(symbol, range, time).last
    return if candles_info.is_a? String
    candles_info[:coin_id] = id
    candles_info[:exchange_id] = exchange.id

    Candle.create(candles_info)
  end

  def show_candlestricks(periods, range, time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    check_candlestick_presence!(periods, range, time)

    candles.where(range: range, :open_time.lte => time).desc(:open_time).limit(periods).to_a
  end

  def create_candle(range = '15m', time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)
    # No se usa INTERVALS antes por los casos de mas de 1 hora
    mins = INTERVALS[range]

    t0 = time - mins.minutes
    return logger.info 'Candle already exists' if candles.where(range: range, open_time: t0).exists?
    candle = exchange.last_candle_for(symbol, mins, time)
    candle['coin_id'] = id
    candle['closed'] = true
    candle['exchange_id'] = exchange.id

    Candle.create(candle)
  end

  def show_candles(periods, range, time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    check_candle_presence!(periods, range, time)

    candles.where(range: range, :open_time.lte => time).desc(:open_time).limit(periods).to_a
  end

  def show_candles_in_time(periods, range, time = Time.now)
    show_candles(periods, range, time).map{ |c| c.attributes.merge(open_time: c[:open_time].in_time_zone('Bogota'), close_time: c[:close_time].in_time_zone('Bogota')) }
  end

  def accumulated_volume(periods, range, time = Time.now)
    r = show_candles(periods, range, time)
    mins = INTERVALS[range]

    accumulated_volume = 0

    r.each do |candle|
      accumulated_volume += candle.volume
    end

    # Muestras las velas de la más reciente a la más antigua
    initial_price = r.last.last_price
    end_price = r.first.last_price

    end_time = r.first.open_time + mins.minutes
    start_time = r.last.open_time

    price_change = (((end_price.to_f * 100) / initial_price.to_f) - 100).round(2)
    range_time = "#{start_time} / #{end_time}"

    { symbol: symbol, accumulated_volume: accumulated_volume, initial_price: initial_price, end_price: end_price, price_change: "#{price_change}%", periods: periods, period_size: range, range_time: range_time }
  end

  def analyze(periods, range, time = Time.now)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    check_candle_presence!(periods, range, time)

    entries = {}

    # velas que existan en X periodos con rango X a partir del tiempo time en orden descendente
    candls = candles.where(range: range, :open_time.lte => time).desc(:open_time).limit(periods).reverse

    b0 = candls.first.bought.to_f
    s0 = candls.first.sold.to_f
    pm0 = candls.first.price_movement.to_f
    v0 = candls.first.volume.to_f

    candls.each do |candle|
      k = candle.open_time
      v = []

      if Flag.where(candle: candle).exists?
        b0 = candle.bought.to_f
        s0 = candle.sold.to_f
        pm0 = candle.price_movement.to_f
        v0 = candle.volume.to_f

        entries[k] = Flag.where(candle: candle).first.items
        next
      end

      v << 'sold' if sold_condition(s0, v0, candle)
      v << 'volume' if volume_condition(v0, candle)
      v << 'price' if price_condition(pm0, v0, b0, candle)
      v << 'price_possible_divergence' if price_possible_divergence(pm0, v0, candle)
      v << 'price_up' if price_up(pm0, v0, candle)
      v << 'volume_hight' if volume_hight_condition(v0, candle)

      v << 'sold_confirmation' if entries[k - mins.minutes] && entries[k - mins.minutes].include?('sold') && sold_confirmation(s0, v0, candle)

      # DEBO CAMBIAR PARA QUE EL TIME SEA EL DE LA VELA ACTUAL Y PROYECTE EL VOLUMEN ACUMILADO HACIA ATRAS
      v << 'accumulated_price_divergence' if accumulated_price_divergence(4, range, candle.open_time)

      v << 'continuous_possible_price_up' if continuous_possible_price_up(3, range, candle.open_time)

      v << 'exit_sold' if exit_sold(s0, v0, pm0, candle)
      v << 'exit_bought' if exit_bought(b0, v0, candle)
      v << 'exit_volume_low' if exit_volume_low(candle)
      v << 'exit_volume_get_out' if exit_volume_get_out(candle)

      v_p = exit_volume_price(v0, candle)
      v << v_p unless v_p.nil?

      hammer = candle.hammer?
      v << hammer if hammer

      b0 = candle.bought.to_f
      s0 = candle.sold.to_f
      pm0 = candle.price_movement.to_f
      v0 = candle.volume.to_f

      Flag.create(symbol: symbol, items: v, created_at: k, candle: candle, coin: self)

      entries[k] = v unless v.empty?
    end

    { symbol => entries }
  end

  private

  def exchange_uniqueness
    symbol.upcase! if symbol
    errors.add(:symbol, I18n.t("validations.exchange_uniqueness", exchange_name: exchange.name)) if exchange && exchange.coins.where(symbol: symbol).exists?
  end

  def check_candle_presence!(periods, range, time)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting

    count = 0
    while count < periods
      t0 = time - ((count + 1) * mins).minutes
      t1 = time - (count * mins).minutes

      create_candle(range, t1) unless candles.where(range: range, open_time: t0).exists?
      count += 1
    end
  end

  def check_candlestick_presence!(periods, range, time)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting

    count = 0
    while count < periods
      t0 = time - ((count + 1) * mins).minutes
      t1 = time - (count * mins).minutes

      create_candlestick(range, t1) unless candles.where(range: range, open_time: t0).exists?
      count += 1
    end
  end

  def sold_condition(s0, v0, candle)
    vol = v0 > 0 ? (v0 * 1.6) : (v0 + (v0 * 1.6).abs)
    candle.sold.to_f >= s0 * 1.6 && candle.price_movement.to_f.between?(-1.5, 100) && candle.volume >= vol
  end

  def sold_confirmation(s0, v0, candle)
    candle.sold.to_f > s0 && candle.price_movement.to_f.between?(-1.5, 100) && candle.volume > v0
  end

  # Volumen mayor 2.4 veces y positivo
  def volume_condition(v0, candle)
    vol = v0 > 0 ? (v0 * 2.4) : (v0 + (v0 * 2.4).abs)
    candle.price_movement.to_f.between?(-1.5, 100) && candle.volume > 0 && candle.volume >= vol
  end

  def volume_hight_condition(v0, candle)
    vol = v0 > 0 ? (v0 * 2.4) : (v0 + (v0 * 2.4).abs)
    candle.price_movement.to_f > 0 && candle.volume > 5
  end

  def price_condition(pm0, v0, b0, candle)
    # price = pm0 > 0 ? (pm0 * 1.6) : (pm0 + (pm0 * 1.6).abs)
    # candle.price_movement.to_f >= price && candle.volume > v0 && candle.bought.to_f < b0
    candle.price_movement.to_f >= (pm0 * 1.6).abs && candle.volume > v0 && candle.bought.to_f < b0
  end

  def price_possible_divergence(pm0, v0, candle)
    candle.price_movement.to_f >= (pm0 * 2.5).abs && candle.volume < v0
  end

  def price_up(pm0, v0, candle)
    candle.price_movement.to_f >= (pm0 * 3).abs && candle.volume > v0
  end

  # sold cae un 35% o mas, precio y volumen negativos
  def exit_sold(s0, v0, pm0, candle)
    candle.sold.to_f <= (s0 * 0.35) && candle.price_movement.to_f < 0 && candle.price_movement.to_f < pm0 && candle.volume < v0
  end

  # volumen cae x2 y bought aumenta x2
  def exit_bought(b0, v0, candle)
    vol = v0 > 0 ? (v0 - (v0 * 2)) : v0 * 2
    candle.bought.to_f >= (b0 * 2) && candle.volume <= vol
  end

  def exit_volume_price(v0, candle)
    return 'exit_volume_price_l5' if candle.volume < v0 && candle.volume < (v0 > 0 ? (v0 - (v0 * 10)) : v0 * 10) && candle.price_movement.to_f < 0
    return 'exit_volume_price_l4' if candle.volume < v0 && candle.volume < (v0 > 0 ? (v0 - (v0 * 7)) : v0 * 7) && candle.price_movement.to_f < 0
    return 'exit_volume_price_l3' if candle.volume < v0 && candle.volume < (v0 > 0 ? (v0 - (v0 * 5)) : v0 * 5) && candle.price_movement.to_f < 0
    return 'exit_volume_price_l2' if candle.volume < v0 && candle.volume < (v0 > 0 ? (v0 - (v0 * 3)) : v0 * 3) && candle.price_movement.to_f < 0
    return 'exit_volume_price_l1' if candle.volume < v0 && candle.volume < (v0 > 0 ? (v0 - (v0 * 1.7)) : v0 * 1.7) && candle.price_movement.to_f < 0
  end

  # def exit_volume_price_l1(v0, candle)
  #   candle.volume < v0 && candle.volume < (v0 * 1.7) && candle.price_movement.to_f < 0
  # end
  #
  # def exit_volume_price_l2(v0, candle)
  #   candle.volume < v0 && candle.volume < (v0 * 3) && candle.price_movement.to_f < 0
  # end
  #
  # def exit_volume_price_l3(v0, candle)
  #   candle.volume < v0 && candle.volume < (v0 * 5) && candle.price_movement.to_f < 0
  # end

  def exit_volume_low(candle)
    candle.volume < -5
  end

  def exit_volume_get_out(candle)
    candle.volume < -15
  end

  def accumulated_price_divergence(periods = 4, range = '15m', time = Time.now)
    r = accumulated_volume(periods, range, time)
    r[:accumulated_volume] < 0 && r[:price_change].to_f > 0
  end

  # def accumulated_volume_up(periods = 4, range = 15, time = Time.now)
  #
  #
  #   accumulated_price_divergence(periods = 4, range = 15, time = Time.now)
  #
  #   r = accumulated_volume(periods, range, time)
  #   r[:accumulated_volume] < 0 && r[:price_change].to_f > 0
  # end

  def continuous_possible_price_up(periods = 3, range = '15m', time = Time.now)
    # Mira que en las ultimas 3 velas el precio haya subido en un rango de 0% a 1%
    # Esto incrementa la posibilidad de que el precio se prepare para una subida grande

    # Revisar que TDI sea positivo para más seguridad --> Linea roja ascendente

    r = show_candles(periods, range, time)
    r.all? { |candle| candle.price_movement.to_f.between?(0, 1) }
  end
end
