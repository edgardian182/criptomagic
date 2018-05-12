class ClearAnalizeResultsJob < ApplicationJob
  queue_as :low

  def perform
    AnalyzeResult.where(:close_time.lt => Time.now - 2.week).each(&:destroy)
  end
end
