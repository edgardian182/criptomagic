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
      raise BinanceError.new(error['msg'], error, params[:symbol])
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
      raise BinanceError.new(error['msg'], error)
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
    res = get_request(path: '/api/v1/aggTrades', params: { symbol: symbol.to_s.upcase, startTime: start_time, endTime: end_time })
    res
  end

  def candlestick_data(symbol, interval, limit, start_time, end_time)
    # [
    #   [
    #     1499040000000,      // Open time                    [0]
    #     "0.01634790",       // Open                         [1]
    #     "0.80000000",       // High                         [2]
    #     "0.01575800",       // Low                          [3]
    #     "0.01577100",       // Close                        [4]
    #     "148976.11427815",  // Volume                       [5]     -->  Total de volumen en symbol (Compra y venta)
    #     1499644799999,      // Close time                   [6]
    #     "2434.19055334",    // Quote asset volume           [7]     -->   Total volumen en BTC => SOLD + BOUGHT (compra y venta)
    #     308,                // Number of trades             [8]
    #     "1756.87402397",    // Taker buy base asset volume  [9]     -->   SOLD en symbol  --> Total vendido
    #     "28.46694368",      // Taker buy quote asset volume [10]    -->   SOLD en BTC
    #     "17928899.62484339" // Ignore                       [11]
    #   ]
    # ]
    res = get_request(path: '/api/v1/klines', params: {
                                                        symbol: symbol.to_s.upcase,
                                                        interval: interval,
                                                        limit: limit,
                                                        startTime: start_time,
                                                        endTime: end_time
                                                      })
    res
  end
end
