class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :coin_name, type: String
  field :coin_symbol, type: String
  field :title, type: String
  field :description, type: String
  field :created_date, type: Time
  field :date_event, type: Time
  field :can_occur_before, type: Boolean
  field :proof, type: String
  field :source, type: String
  field :categories, type: Array, default: []

  index({ date_event: 1, title: 1, coin_name: 1 }, background: true, unique: true)
  index({ date_event: 1 }, background: true)
  index({ coin_name: 1 }, background: true)
  index({ categories: 1 }, background: true)
  index({ date_event: 1, coin_name: 1, categories: 1 }, background: true)

  validate :date_title_coin_uniqueness

  private

  def date_title_coin_uniqueness
    errors.add(:event, "already exists") if Event.where(date_event: date_event, title: title, coin_name: coin_name).exists?
  end
end
