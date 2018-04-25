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
    coin = market.coin_info(symbol)
    return logger.info "Coin #{symbol} was not found in MarketCap database, should add it manually" if coin.empty?
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')
    coin['symbol'] = 'IOTA' if coin['symbol'] == 'MIOTA'

    coins.create(coin)
  end

  def update_coin(symbol)
    symbol = symbol.upcase
    outdated_coin = coins.where(symbol: symbol)
    return unless outdated_coin
    coin = market.coin_info(symbol)
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')

    outdated_coin.update(coin)
  end

  def update_coins
    coins.each do |coin|
      update_coin(coin.symbol)
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

  def analyze_coins(range, flag = '', time = Time.now, all: true)
    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    # Inicialmente todas las flags se deben cumplir
    # flag = %w[price_possible_divergence hammer_hight accumulated_price_divergence] if flag.empty?
    flag = FLAGS[flag]
    flag = FLAGS['f1'] if flag.blank?

    if AnalyzeResult.where(range: range, flag: flag, open_time: time, all_filters: all).exists?
      return {
        Time.now => AnalyzeResult.where(range: range, flag: flag, open_time: time, all_filters: all).first.to_review,
        flag: flag
      }
    end

    to_review = []
    coins.each do |coin|
      a = coin.analyze(2, range)
      alerts = a.values.first.values.flatten.uniq
      to_review << coin.symbol if flag.all? { |f| alerts.include? f } && all
      to_review << coin.symbol if flag.any? { |f| alerts.include? f } && !all
      # to_review << coin.symbol if (a.values.first.values.flatten.uniq & flag).any?
    end

    AnalyzeResult.create(range: range, flag: flag, open_time: time, to_review: to_review, all_filters: all)

    {
      Time.now => to_review,
      flag: flag
    }
  end
end
