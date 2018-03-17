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
  has_many :candles
  belongs_to :binance

  # - validations -
  validates_presence_of :symbol
  validates_uniqueness_of :symbol

  def price
    binance.price_for(symbol)
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
end
