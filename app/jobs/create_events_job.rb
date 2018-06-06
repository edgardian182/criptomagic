class CreateEventsJob < ApplicationJob
  require 'future'

  queue_as :low

  def perform
    Coin.all.uniq(&:name).each do |c|
      future { c.create_events }
    end
  end
end
