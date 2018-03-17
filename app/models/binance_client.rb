class BinanceClient
  def initialize
    @connection = Faraday.new(url: 'https://api.binance.com') do |faraday|
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_request(path:, params:)
    res = @connection.get "#{path}", params, 'Content-Type': 'application/json'
    if res.status != 200
      error = Oj.load(res.body)
      # raise MasterbaseError.new(error['Error']['Message']['Value'], error)
    end

    Oj.load(res.body)
  end

  def post_request(path:, query:, data:, type: 'x-www-form-urlencoded') # Generally :json
    res = @connection.post(path) do |req|
      req.headers['Content-Type'] = "application/#{type}"
      req.body = Oj.dump(data)
      req.params.merge! query
    end

    if res.status != 200
      error = Oj.load(res.body)
      # raise MasterbaseError.new(error['Error']['Message']['Value'], error)
    end
    p res.body

    Oj.load(res.body)
  end

end
