# Base Classes
Eapp.create(name: 'CriptoMagic') unless Eapp.count > 0
Binance.create(name: 'Binance') unless Binance.count > 0

# Create coins
binance = Binance.last
binance.create_coins

binance.create_coin('BTC')

# Create candles
Coin.new_candle(binance.id, '15m')

# Create events
Coin.new_events_token if Eapp.where(name: 'CriptoMagic').first.events_exp < (Time.now + 2.days)
Eapp.where(name: 'CriptoMagic').first.update_marketcal_coins
Coin.all.uniq(&:name).each(&:create_events)

# Remember to run: rake db:mongoid:create_indexes
