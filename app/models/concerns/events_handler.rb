# Added to Coin Model
module EventsHandler
  extend ActiveSupport::Concern

  included do
  end

  def events
    Event.where(coin_name: name).asc(:date_event).to_a
  end

  def marketcal_client
    @marketcal_client ||= MarketcalClient.new
  end

  def create_events
    eapp = Eapp.where(name: 'CriptoMagic').first
    return logger.info 'Events token expired' if eapp.events_token_expired?

    name_id = eapp.marketcal_coins.find { |coin| coin['name'] == name.humanize }
    name_id = eapp.marketcal_coins.find { |coin| coin['name'] == name } if name_id.blank?
    return logger.info "#{name} was not found in MarketCal coins" unless name_id
    name_id = name_id['id']

    events = marketcal_client.events_info(name_id) # coin name
    return logger.info "There are no events for #{name}" if events.blank?

    events.each do |event|
      old_event = Event.where(date_event: event['date_event'].to_time, title: event['title'], coin_name: name).first
      data = {
        coin_name: name,
        coin_symbol: symbol,
        title: event['title'],
        description: event['description'],
        created_date: event['created_date'].to_time,
        date_event: event['date_event'].to_time,
        can_occur_before: event['can_occur_before'],
        proof: event['proof'],
        source: event['source'],
        categories: event['categories'].map { |c| c['name'] }
      }
      if old_event
        old_event.set(data)
      else
        Event.create(data)
      end
    end
  end

  class_methods do
    def create_events
      eapp = Eapp.where(name: 'CriptoMagic').first
      cal_coins = eapp.marketcal_coins_total

      Coin.all.uniq(&:name).each(&:create_events)
    end

    def new_events_token
      marketcal_client ||= MarketcalClient.new
      res = marketcal_client.token
      eapp = Eapp.where(name: 'CriptoMagic').first
      eapp.events_token = res['access_token']
      eapp.events_exp = Time.now + (res['expires_in'] / 3600 / 24).days
      eapp.save
    end

    def new_events
      CreateEventsJob.perform_later
    end

    def with_events_in(n_days)
      Event.where(date_event: { :$gt => Time.now.beginning_of_day + n_days.days, :$lt => Time.now.end_of_day + n_days.days }).map(&:coin_name).uniq
    end

    def with_events_next(n_days)
      Event.where(date_event: { :$gt => Time.now.beginning_of_day, :$lt => Time.now.end_of_day + n_days.days }).map(&:coin_name).uniq
    end
  end
end
