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

  def agg_trades_for(symbol, start_time = ((Time.now - 5.minutes).to_i * 1000), end_time = (Time.now.to_i * 1000))
    # {
    #   "a": 26129,         // Aggregate tradeId
    #   "p": "0.01633102",  // Price
    #   "q": "4.70443515",  // Quantity
    #   "f": 27781,         // First tradeId
    #   "l": 27781,         // Last tradeId
    #   "T": 1498793709153, // Timestamp
    #   "m": true,          // Was the buyer the maker?
    #   "M": true           // Was the trade the best price match?
    # }
    res = get_request(path: '/api/v1/aggTrades', params: { symbol: symbol.to_s.upcase + 'BTC', startTime: start_time, endTime: end_time })
    res
  end

end
