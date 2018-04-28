Binance.create(name: 'Binance') unless Binance.count > 0

# Create coins
binance = Binance.last
binance.create_coins

binance.create_coin('BTC')

# Fix iota
iota = Coin.search 'miota'
if iota
  iota.symbol = 'IOTA'
  iota.save
end

Coin.new_candle(binance.id, '15m')
