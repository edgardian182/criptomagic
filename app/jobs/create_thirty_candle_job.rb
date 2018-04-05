class CreateThirtyCandleJob < ApplicationJob
  require 'future'

  queue_as :default

  def perform
    Coin.all.each do |c|
      future { c.analyze(1, '30m') }
    end
  end
end
