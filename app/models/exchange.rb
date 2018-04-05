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
end
