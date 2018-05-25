class ClearAnalyzeResultsJob < ApplicationJob
  queue_as :low

  def perform
    AnalyzeResult.where(:close_time.lt => Time.now - 1.week).each(&:destroy)
  end
end
