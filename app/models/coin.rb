class Coin
  include Mongoid::Document
  include Mongoid::Timestamps

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
  field :last_updated, type: Integer # Pasat a int y luego Time.at()

  # - relationships -
  has_many :candles, dependent: :destroy
  belongs_to :exchange

  # - validations -
  validates_presence_of :symbol
  validate :exchange_uniqueness, on: :create

  def update_coin
    coin = exchange.market.coin_info(symbol)
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')

    update(coin)
  end

  def price
    exchange.price_for(symbol)
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

  def analyze(periods, range)
    candles = Candle.where(coin: self, range: range).limit(periods)
  end

  def last_updated
    Time.at(self[:last_updated])
  end

  private

  def exchange_uniqueness
    symbol.upcase! if symbol
    errors.add(:symbol, I18n.t("validations.exchange_uniqueness", exchange_name: exchange.name)) if exchange && exchange.coins.where(symbol: symbol).exists?
  end
end
