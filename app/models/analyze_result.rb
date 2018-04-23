class AnalyzeResult
  include Mongoid::Document
  include TimeHandler

  field :range, type: String
  field :flag, type: Array, default: []
  field :open_time, type: Time
  field :to_review, type: Array, default: []
  field :all_filters, type: Boolean

  validates_presence_of :range, :open_time, :all_filters
end
