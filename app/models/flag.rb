class Flag
  include Mongoid::Document

  # - fields
  field :symbol, type: String
  field :items, type: Array, default: []
  field :created_at, type: Time

  # - relationships
  belongs_to :coin
  belongs_to :candle

  #  - validations
  validates_presence_of :symbol

  # - indexes
  index({ candle_id: 1 }, background: true)
end
