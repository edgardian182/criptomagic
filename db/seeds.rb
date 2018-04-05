Binance.create(name: 'Binance') unless Binance.count > 0

# Create coins
binance = Binance.last
binance.symbols.each do |symbol|
  next if symbol.blank?
  binance.create_coin(symbol)
end

# Fix iota
iota = Coin.search 'miota'
iota.symbol = 'IOTA'
iota.save

Coin.new_candle(binance.id)
