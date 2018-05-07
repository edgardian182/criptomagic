Binance.create(name: 'Binance') unless Binance.count > 0

# Create coins
binance = Binance.last
binance.create_coins

binance.create_coin('BTC')

Coin.new_candle(binance.id, '15m')
