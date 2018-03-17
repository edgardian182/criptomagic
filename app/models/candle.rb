class Candle
  include Mongoid::Document

  field :bought, type: String
  field :sold, type: String
  field :range, type: String
  field :volume, type: Float
  field :init_price, type: String
  field :last_price, type: String
  field :max_price, type: String
  field :min_price, type: String
  field :price_movement, type: String
  field :time, type: Time

  belongs_to :coin
end
