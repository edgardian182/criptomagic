class Binance
  include Mongoid::Document

  # - fields

  # - relationships
  has_many :coins

  def client
    @client ||= BinanceClient.new
  end

  def market
    @market ||= MarketcapClient.new
  end

  def create_coin(symbol)
    symbol = symbol.upcase
    return logger.info 'Coin already exists' if coins.where(symbol: symbol).exists?
    coin = market.coin_info(symbol)
    return logger.info "Coin #{symbol} was not found in MarketCap database, should add it manually" if coin.empty?
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')

    coins.create(coin)
  end

  def update_coin(symbol)
    symbol = symbol.upcase
    outdated_coin = coins.where(symbol: symbol)
    return unless outdated_coin
    coin = market.coin_info(symbol)
    coin.delete('id')
    coin['volume_24h_usd'] = coin.delete('24h_volume_usd')

    outdated_coin.update(coin)
  end

  def update_coins
    coins.each do |coin|
      update_coin(coin.symbol)
    end
  end

  def search_coin(symbol)
    coins.where(symbol: symbol.upcase).first
  end

  def qty_moved(symbol, limit = 500, btc: true)
    # [{"id"=>9274551, "price"=>"0.01940800", "qty"=>"0.17000000", "time"=>1520863850247, "isBuyerMaker"=>false, "isBestMatch"=>true}]

    # Las compras aparecen en ROJO en TradeHistory y las ventas en VERDE contrario al libro de ordenes de la izquierda

    # Usar para ver que tanto se esta moviendo la moneda con el RANGE (Más minutos menos movimiento)
      # Si el rango es de 15 minutos o menos se está moviendo bastante (500 trades)
    # Usar para ver movimiento del precio
      # Si vendo más de lo que compro su precio subirá al hacerse más excaso cada vez
        # bought: 100  sold: 200  --> Precio sube


    # Probar ROBOT que compre cuando SOLD sea mayor que bought y venda cuando esto sea al reves  --> Usar 300 periodos (trades)
      # Escalonarlo cada 100 periodos

    qty_buy = 0
    qty_sell = 0

    r = client.get_request(path: '/api/v1/trades', params: { symbol: symbol.to_s.upcase + 'BTC', limit: limit })
    init_time = Time.at(r.first['time'] / 1000)
    last_time = Time.at(r.last['time'] / 1000)
    range = (last_time - init_time) / 60

    if btc
      r.each do |trade|
        price = trade['price'].to_f
        trade['isBuyerMaker'] ? qty_buy += (trade['qty'].to_f * price) : qty_sell += (trade['qty'].to_f * price)
      end
      return { bought: "#{qty_buy} BTC", sold: "#{qty_sell} BTC", range: "#{range} min" }
    else
      r.each do |trade|
        trade['isBuyerMaker'] ? qty_buy += trade['qty'].to_f : qty_sell += trade['qty'].to_f
      end
      return { bought: "#{qty_buy} #{symbol}", sold: "#{qty_sell} #{symbol}", range: "#{range} min" }
    end
  end

  def peridical_movement(symbol, btc = true)
    movement = {}
    movement[:r1] = qty_moved(symbol, 100, btc: btc)
    movement[:r2] = qty_moved(symbol, 200, btc: btc)
    movement[:r3] = qty_moved(symbol, 300, btc: btc)
    movement[:r4] = qty_moved(symbol, 400, btc: btc)
    movement[:r5] = qty_moved(symbol, 500, btc: btc)
    # movement.each { |k| movement[k].delete(:range) }
    # 9283851
    movement
  end

  def data(symbol, start_time = ((Time.now - 5.minutes).to_i * 1000), end_time = (Time.now.to_i * 1000))
    # maximo de tiempo es de una hora para la consulta en el rango

    qty_buy = 0
    qty_sell = 0

    max_price = 0
    min_price = 1

    r = client.get_request(path: '/api/v1/aggTrades', params: { symbol: symbol.to_s.upcase + 'BTC', startTime: start_time, endTime: end_time })

    init_price = r.first['p']
    last_price = r.last['p']
    price_movement = (((last_price.to_f * 100) / init_price.to_f) - 100).round(2)

    r.each do |trade|
      price = trade['p'].to_f
      max_price = price if price > max_price
      min_price = price if price < min_price
      trade['m'] ? qty_buy += (trade['q'].to_f * price) : qty_sell += (trade['q'].to_f * price)
    end

    # Me interesa el volumen de venta, si es positivo precio subira
    volume = qty_sell - qty_buy

    return { bought: "#{qty_buy} BTC", sold: "#{qty_sell} BTC", range: "#{(end_time - start_time) / 1000 / 60} min", volume: volume, init_price: init_price, last_price: last_price, max_price: format('%.8f', max_price), min_price: format('%.8f', min_price), price_movement: "#{price_movement}%", time: Time.at(start_time / 1000) }
  end

  def volume_and_price(symbol)
    end_time = Time.now.to_i * 1000
    time5 = (Time.now - 5.minutes).to_i * 1000
    time15 = (Time.now - 15.minutes).to_i * 1000
    time30 = (Time.now - 30.minutes).to_i * 1000
    time60 = (Time.now - 60.minutes).to_i * 1000

    d1 = data(symbol, time5, end_time)
    d2 = data(symbol, time15, end_time)
    d3 = data(symbol, time30, end_time)
    d4 = data(symbol, time60, end_time)

    [d1, d2, d3, d4]
  end

  def inspect_coins
    inspection = {}
    sym = symbols[0,10]
    sym.each do |symbol|
      next if symbol.blank?
      count = 0
      volume_and_price(symbol).each do |data|
        count += 1 if data[:volume].to_f > 0
      end
      inspection[symbol] = count
    end

    inspection
  end

  def time_formatting(mins, time)
    minutes = time.min
    return time if minutes == 0
    unless mins == 60
      minutes -= 1 while minutes % mins != 0
      time = time.change(min: minutes)
      return time
    end
    time = time.change(min: 0)
    time
  end

  def last_period_from(symbol, periods, mins = 60, time = Time.now, fake_time: false)
    result = {}
    info = []
    accumulated_volume = 0

    time = time_formatting(mins, time) unless fake_time
    count = 0
    while count < periods
      t0 = (time - ((count + 1) * mins).minutes).to_i * 1000
      t1 = (time - (count * mins).minutes).to_i * 1000

      r = data(symbol, t0, t1)
      accumulated_volume += r[:volume]

      info << r

      count += 1

      initial_price = r[:init_price] if count == periods
      end_price = r[:last_price] if count == 1

      start_time = Time.at(t0 / 1000) if count == periods
      end_time = Time.at(t1 / 1000) if count == 1

    end

    price_change = (((end_price.to_f * 100) / initial_price.to_f) - 100).round(2)
    range = "#{start_time} / #{end_time}"

    result[symbol.upcase] = info
    [result, { symbol: "#{symbol.upcase}/BTC", accumulated_volume: accumulated_volume, initial_price: initial_price, end_price: end_price, price_change: "#{price_change}%", periods: periods, period_size: mins, range: range }]
  end

  def price_for(symbol)
    client.get_request(path: '/api/v3/ticker/price', params: { symbol: symbol.to_s.upcase + 'BTC' }) if symbol
  end

  def coin_prices
    prices = []
    r = client.get_request(path: '/api/v3/ticker/price', params: {})
    r.each do |price|
      prices << price if price['symbol'].rindex('BTC')
    end
    prices
  end

  def symbols
    symbols = []
    r = client.get_request(path: '/api/v1/exchangeInfo', params: {})
    r['symbols'].each do |symbol|
      next unless symbol['symbol'].rindex('BTC')
      i = symbol['symbol'].rindex('BTC')
      s = symbol['symbol'].slice(0...i)
      symbols << s
    end
    symbols
  end
end
