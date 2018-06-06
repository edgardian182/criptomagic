class MarketcalClient
  def initialize
    @connection = Faraday.new(url: 'https://api.coinmarketcal.com') do |faraday|
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_request(path:, params:)
    res = @connection.get "#{path}", params, 'Content-Type': 'application/json'
    if res.status != 200
      error = { status: res.status, message: res.reason_phrase }
      # raise MarketcalError.new(error[:message], error)
    end

    Oj.load(res.body)
  end

  def token
    get_request(path: '/oauth/v2/token', params: { grant_type: 'client_credentials', client_id: ENV['CLIENT_ID'], client_secret: ENV['CLIENT_SECRET'] })
  end

  # Array of events
  def events_info(coins, page = 1, max = 150)
    params = {
      access_token: Eapp.where(name: 'CriptoMagic').first.events_token,
      page: page.to_s,
      max: max.to_s,
      # dateRangeStart: ,
      # dateRangeEnd: ,
      coins: coins.parameterize,
      # categories: ,
      sortBy: 'created_desc'
      # showOnly: ,
    }

    get_request(path: "/v1/events", params: params)
  end

  def event_categories
    get_request(path: '/v1/categories', params: { access_token: Eapp.where(name: 'CriptoMagic').first.events_token })
  end

  def coins
    get_request(path: '/v1/coins', params: { access_token: Eapp.where(name: 'CriptoMagic').first.events_token })
  end
end
