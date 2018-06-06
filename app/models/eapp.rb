class Eapp
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  # CoinMarketCal
  field :events_token, type: String, default: ''
  field :events_exp, type: Time, default: Time.now
  field :marketcal_coins, type: Array, default: []

  validates_presence_of :name
  validates_uniqueness_of :name

  index({ name: 1 }, background: true, unique: true)

  def update_marketcal_coins
    self.marketcal_coins = MarketcalClient.new.coins
    save
  end

  def events_token_expired?
    events_exp.blank? || (events_exp <= Time.now + 1.day)
  end
end
