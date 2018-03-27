class Candle
  include Mongoid::Document

  # - fields
  field :bought, type: String
  field :sold, type: String
  field :range, type: Integer
  field :volume, type: Float
  field :init_price, type: String
  field :last_price, type: String
  field :max_price, type: String
  field :min_price, type: String
  field :price_movement, type: String
  field :time, type: Time
  field :symbol, type: String

  # - relationships
  belongs_to :coin

  # - validations
  validates_presence_of :bought, :sold, :range, :volume, :init_price, :last_price, :max_price, :min_price, :price_movement, :time
  validate :time_range_uniqueness

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

  private

  def time_range_uniqueness
    errors.add(:time, "already exist for #{range} range") if Candle.where(range: range, time: time, coin_id: coin.id).exists?
  end
end
