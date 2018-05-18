class Exchange
  include Mongoid::Document
  include Mongoid::Timestamps
  include TimeHandler

  # - fields
  field :name, type: String
  field :last_errors, type: Array, default: []

  # - relationships
  has_many :coins, dependent: :destroy
  has_many :candles, dependent: :destroy

  # - validations
  validates_presence_of :name
  validates_uniqueness_of :name

  FLAGS = {
    "f1" => %w[price_possible_divergence hammer_hight accumulated_price_divergence],
    "f2" => %w[hammer_hight accumulated_price_divergence],
    "f3" => %w[price_possible_divergence hammer_hight],
    "f4" => %w[price_possible_divergence accumulated_price_divergence],
    "f5" => %w[hammer_hight],
    "f6" => %w[accumulated_price_divergence],
    "f7" => %w[price_possible_divergence],
    "f8" => %w[volume_hight hammer_hight],
    "f9" => %w[volume_hight accumulated_price_divergence],
    "f10" => %w[continuous_possible_price_up],
    "f11" => %w[price_possible_divergence hammer_hight accumulated_price_divergence continuous_possible_price_up],
    "f12" => %w[pump],
    "f13" => %w[dump]
  }.freeze

  def client
    false
  end

  def price_for(symbol)
    false
  end

  def market
    @market ||= MarketcapClient.new
  end

  def create_coin(symbol)
    symbol = symbol.upcase
    return logger.info 'Coin already exists' if coins.where(symbol: symbol).exists?
    symbol = 'BCH' if symbol == 'BCC' && (name == 'Binance' || name == 'Bittrex')
    coin = market.coin_info(symbol)
    return logger.info "Coin #{symbol} was not found in MarketCap database, should add it manually" if coin.empty?
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
    coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'
    coin['symbol'] = 'BCC' if coin['symbol'] == 'BCH' && (name == 'Binance' || name == 'Bittrex')

    coins.create(coin)
  end

  def create_coins
    exchange_symbols = symbols
    exchange_symbols.uniq!
    count = exchange_symbols.count
    coins_info = market.coins_info
    coins_info.each do |coin|
      next unless exchange_symbols.include? coin['symbol']
      count -= 1
      next if coins.where(symbol: coin['symbol']).exists?
      next if coin['symbol'] == 'BCC' # BitConnect
      coin.delete('id')
      coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
      coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'
      coin['symbol'] = 'BCC' if coin['symbol'] == 'BCH' && (name == 'Binance' || name == 'Bittrex')

      coins.create(coin)
      break if count == 0
    end
  end

  def update_coin(symbol)
    symbol = symbol.upcase
    outdated_coin = coins.where(symbol: symbol)
    symbol = 'BCH' if symbol == 'BCC' && (name == 'Binance' || name == 'Bittrex')
    return unless outdated_coin
    coin = market.coin_info(symbol)
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
    coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'
    coin['symbol'] = 'BCC' if coin['symbol'] == 'BCH' && (name == 'Binance' || name == 'Bittrex')

    outdated_coin.update(coin)
  end

  def update_coins
    coins_info = market.coins_info
    coins_info.each do |coin|
      next unless coins.where(symbol: coin['symbol']).exists?
      next if coin['symbol'] == 'BCC' # BitConnect
      coin.delete('id')
      coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
      coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'
      coin['symbol'] = 'BCC' if coin['symbol'] == 'BCH' && (name == 'Binance' || name == 'Bittrex')

      outdated_coin = coins.where(symbol: coin['symbol']).first
      outdated_coin.update(coin) if outdated_coin.updated_at < (Time.now - 1.minutes)
      outdated_coin.set(updated_at: Time.now)
    end
  end

  def update_coins_24h_volume
    d = daily_coin_data

    d.each do |coin|
      i = coin['symbol'].rindex('BTC')
      symbol = coin['symbol'].slice(0...i)
      c = coins.where(symbol: symbol).first
      c.set(volume_24h_btc: coin['quoteVolume']) if c
    end
  end

  def search_coin(symbol)
    coins.where(symbol: symbol.upcase).first
  end

  def clean_errors
    set(last_errors: [])
  end

  def show_flags
    FLAGS
  end

  def analyze_coins(periods, range, flag = '', time = Time.now, all: true)
    return logger.info 'Time parameter surpass actual time for an analysis' if time > Time.now

    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    # Inicialmente todas las flags se deben cumplir
    # flag = %w[price_possible_divergence hammer_hight accumulated_price_divergence] if flag.empty?
    flag = FLAGS[flag]
    flag = FLAGS['f1'] if flag.blank?

    analysis = []

    count = 0
    while count < periods.to_i
      t0 = time - ((count + 1) * mins).minutes # open_time
      t1 = time - (count * mins).minutes # close_time

      if AnalyzeResult.where(range: range, flag: flag, close_time: t1, all_filters: all).exists?
        result = AnalyzeResult.where(range: range, flag: flag, close_time: t1, all_filters: all).first
        analysis << {
                      result.close_time => result.to_review,
                      flag: flag
                    }
      else
        to_review = []
        coins.each do |coin|
          a = coin.analyze(2, range, t0)
          if a[coin.symbol][t0].nil?
            to_review << 'no_candle'
            break
          end
          alerts = a.values.first.values.flatten.uniq
          to_review << coin.symbol if flag.all? { |f| alerts.include? f } && all
          to_review << coin.symbol if flag.any? { |f| alerts.include? f } && !all
          # to_review << coin.symbol if (a.values.first.values.flatten.uniq & flag).any?
        end

        if to_review.include?('no_candle')
          analysis << {
            t1 => to_review,
            flag: ['No se ha creado la vela, intenta de nuevo']
          }
        else
          result = AnalyzeResult.create(range: range, flag: flag, close_time: t1, to_review: to_review, all_filters: all)
          analysis << {
                        result.close_time => to_review,
                        flag: flag
                      }
        end
      end

      count += 1
    end
    analysis
  end
end
