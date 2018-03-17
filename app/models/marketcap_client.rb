class MarketcapClient
  def initialize
    @connection = Faraday.new(url: 'https://api.coinmarketcap.com') do |faraday|
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

  def coin_info(name)
    name = name.upcase
    res = get_request(path: "/v1/ticker/#{name}/", params: {})
    return res.first unless res.class == Hash && res['error']
    coins_info.each do |coin|
      return coin if coin['symbol'] == name
    end

    return {}
  end

  def coins_info
    get_request(path: "/v1/ticker/", params: { limit: 0 }) # Retorna todas las monesas
  end
end
