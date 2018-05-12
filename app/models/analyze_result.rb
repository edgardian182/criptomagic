class AnalyzeResult
  include Mongoid::Document
  include TimeHandler

  field :range, type: String
  field :flag, type: Array, default: []
  field :close_time, type: Time # The analysis is done at candle close_time
  field :to_review, type: Array, default: []
  field :all_filters, type: Boolean

  validates_presence_of :range, :close_time, :all_filters
  validate :time_range_filter_uniqueness

  # - indexes
  # index({ range: 1, open_time: -1 }, background: true)
  # index({ range: 1, open_time: -1, flag: 1 }, background: true)
  index({ range: 1, close_time: -1, flag: 1, all_filters: 1 }, background: true)

  private

  def time_range_filter_uniqueness
    errors.add(:time, "already exist for #{range} range, #{flag} flags and #{close_time} time") if AnalyzeResult.where(range: range, close_time: close_time, flag: flag).exists?
  end
end
