class Binance < Exchange
  def client
    @client ||= BinanceClient.new
  end

  def candlestick_for(symbol, periods = 1, range = '15m', time = Time.now)
    return false unless INTERVALS.include?(range)

    symbol.upcase!
    symbol = symbol != 'BTC' ? symbol + 'BTC' : symbol + 'USDT'

    mins = %w[1m 3m 5m 15m 30m].include?(range) ? range.to_i : 60 # Used for time_formatting
    time = time_formatting(mins, time)

    t0 = (time - (INTERVALS[range].minutes * periods)).to_i * 1000
    t1 = time.to_i * 1000

    r = client.candlestick_data(symbol, range, periods, t0, t1)
    return 'error' if r == 'error'

    candles = []
    r.each do |candle|
      c = {}
      c[:bought] = candle[7].to_f - candle[10].to_f
      c[:sold] = candle[10].to_f
      c[:range] = range
      c[:volume] = candle[10].to_f - (candle[7].to_f - candle[10].to_f)
      c[:init_price] = candle[1]
      c[:last_price] = candle[4]
      c[:max_price] = candle[2]
      c[:min_price] = candle[3]
      c[:price_movement] = "#{(((candle[4].to_f * 100) / candle[1].to_f) - 100).round(2)}%"
      c[:open_time] = Time.at(candle[0] / 1000)
      c[:close_time] = Time.at(candle[6] / 1000)
      c[:trades] = candle[8]
      c[:symbol] = symbol
      c[:closed] = time >= Time.at(candle[6] / 1000)
      candles << c
    end

    candles.reverse

  rescue BinanceError => e
    handle_error(e)
  end

  def last_candlestick_for(symbol, range = '15m', time = Time.now)
    candlestick_for(symbol, 1, range, time)
  end

  def period_movement_for(symbol, start_time = ((Time.now - 15.minutes).to_i * 1000), end_time = (Time.now.to_i * 1000))
    # maximo de tiempo es de una hora para la consulta en el rango
    # el tiempo es en milisegundos por eso se multiplica por 1000
    symbol.upcase!
    symbol = symbol != 'BTC' ? symbol + 'BTC' : symbol + 'USDT'

    qty_buy = 0
    qty_sell = 0

    max_price = 0
    min_price = 1

    # Devuelve todos los trades hechos en el periodo de tiempo dado [{}]
    r = client.agg_trades_for(symbol, start_time, end_time)
    return logger.info "#{r['msg']} in agg_trades_for #{symbol}" if r.class == Hash && r['msg']
    return logger.info "client error" if r.empty?

    init_price = r.first['p']
    last_price = r.last['p']
    price_movement = (((last_price.to_f * 100) / init_price.to_f) - 100).round(2)

    r.each do |trade|
      price = trade['p'].to_f
      max_price = price if price > max_price
      min_price = price if price < min_price
      qty_moved = trade['q'].to_f * price
      trade['m'] ? qty_buy += qty_moved : qty_sell += qty_moved
    end

    # Me interesa el volumen de venta, si es positivo precio subira
    volume = qty_sell - qty_buy

    return {
      bought: "#{qty_buy} BTC",
      sold: "#{qty_sell} BTC",
      range: INTERVALS.key((end_time - start_time) / 1000 / 60),
      volume: volume,
      init_price: init_price,
      last_price: last_price,
      max_price: format('%.8f', max_price),
      min_price: format('%.8f', min_price),
      price_movement: "#{price_movement}%",
      open_time: Time.at(start_time / 1000),
      close_time: Time.at(end_time / 1000),
      trades: r.length,
      symbol: symbol
    }
  end

  def last_candle_for(symbol, mins = 15, time = Time.now)
    time = time_formatting(mins, time)

    t0 = (time - mins.minutes).to_i * 1000
    t1 = time.to_i * 1000

    period_movement_for(symbol, t0, t1)
  end

  def volume_moved_for(symbol, limit = 500, btc: true)
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
    movement[:r1] = volume_moved_for(symbol, 100, btc: btc)
    movement[:r2] = volume_moved_for(symbol, 200, btc: btc)
    movement[:r3] = volume_moved_for(symbol, 300, btc: btc)
    movement[:r4] = volume_moved_for(symbol, 400, btc: btc)
    movement[:r5] = volume_moved_for(symbol, 500, btc: btc)
    # movement.each { |k| movement[k].delete(:range) }
    # 9283851
    movement
  end

  def volume_and_price(symbol)
    end_time = Time.now.to_i * 1000
    time5 = (Time.now - 5.minutes).to_i * 1000
    time15 = (Time.now - 15.minutes).to_i * 1000
    time30 = (Time.now - 30.minutes).to_i * 1000
    time60 = (Time.now - 60.minutes).to_i * 1000

    d1 = period_movement_for(symbol, time5, end_time)
    d2 = period_movement_for(symbol, time15, end_time)
    d3 = period_movement_for(symbol, time30, end_time)
    d4 = period_movement_for(symbol, time60, end_time)

    [d1, d2, d3, d4]
  end

  def last_movement_for(symbol, periods = 2, mins = 60, time = Time.now, fake_time: false)
    result = {}
    info = []
    accumulated_volume = 0

    time = time_formatting(mins, time) unless fake_time
    count = 0
    while count < periods
      t0 = (time - ((count + 1) * mins).minutes).to_i * 1000
      t1 = (time - (count * mins).minutes).to_i * 1000

      r = period_movement_for(symbol, t0, t1)
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
    symbol.upcase!
    symbol = symbol != 'BTC' ? symbol + 'BTC' : symbol + 'USDT'

    client.get_request(path: '/api/v3/ticker/price', params: { symbol: symbol }) if symbol
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

  def handle_error(error)
    logger.error "with exchange: #{name}(#{id}) #{error.error_code} #{error.message} [#{error.symbol}]"
    last_errors << { error.error_code.to_s => { message: error.message, symbol: error.symbol, time: Time.now } }
    save
    return 'error'
  end
end
