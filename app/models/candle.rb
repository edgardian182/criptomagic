class Candle
  include Mongoid::Document

  # - fields
  field :bought, type: String
  field :sold, type: String
  field :range, type: String
  field :volume, type: Float
  field :init_price, type: String
  field :last_price, type: String
  field :max_price, type: String
  field :min_price, type: String
  field :price_movement, type: String
  field :open_time, type: Time
  field :close_time, type: Time
  field :trades, type: Integer
  field :closed, type: Boolean
  field :symbol, type: String

  # - relationships
  belongs_to :coin
  belongs_to :exchange

  has_many :flags, dependent: :destroy

  # - validations
  validates_presence_of :bought, :sold, :range, :volume, :init_price, :last_price, :max_price, :min_price, :price_movement, :open_time
  validate :time_range_uniqueness

  after_create :analyze_coin

  # - indexes
  index({ exchange_id: 1, range: 1, open_time: -1 }, background: true)
  index({ coin_id: 1, range: 1, open_time: -1 }, background: true)
  index({ range: 1, open_time: -1 }, background: true)

  def hammer?
    if price_movement.to_f > 0
      body = last_price.to_f - init_price.to_f
      upper_shadow = max_price.to_f - last_price.to_f
      lower_shadow = init_price.to_f - min_price.to_f
    elsif price_movement.to_f < 0
      body = init_price.to_f - last_price.to_f
      upper_shadow = max_price.to_f - init_price.to_f
      lower_shadow = last_price.to_f - min_price.to_f
    else
      return false
    end

    return 'hammer_low' if (upper_shadow / body > 2) && ((upper_shadow / body) / (lower_shadow / body) >= 2)
    return 'hammer_hight' if (lower_shadow / body > 2) && ((lower_shadow / body) / (upper_shadow / body) >= 2)
  end

  def analyze_coin
    AnalyzeCoinJob.perform_later(coin.id.to_s, 2, range)
  end

  private

  def time_range_uniqueness
    errors.add(:time, "already exist for #{range} range") if Candle.where(range: range, open_time: open_time, coin_id: coin.id).exists?
  end
end
