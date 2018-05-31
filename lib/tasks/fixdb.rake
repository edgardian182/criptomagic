namespace :fixdb do
  task count_15m_candles: :environment do
    b = Binance.last
    puts Candle.collection.aggregate([{ :$match => { exchange_id: b.id, range: '15m' } }]).count
  end

  task remove_dup_candles: :environment do
    Exchange.each do |e|
      # MONGO
      # db.candles.aggregate([{$project: {symbol: 1, open_time: 1, range: 1}}, {$group: {_id: { symbol: "$symbol", range: "$range", open_time: "$open_time"}, uniqueIds:  {$addToSet: "$_id" }, count:  {$sum: 1} }}, {$match: { count: {$gt: 1} }  }])

      pipeline = [
        { :$match => { exchange_id: e.id } },
        { :$project => { symbol: 1, range: 1, open_time: 1 } },
        { :$group => { _id: { symbol: "$symbol", range: "$range", open_time: "$open_time" }, uniqueIds: { :$addToSet => "$_id" }, count: { :$sum => 1 } } },
        { :$match => { count: { :$gt => 1 } } }
      ]

      Candle.collection.find.aggregate(pipeline).each do |dup|
        count = dup['count']
        while count > 1
          Candle.find(dup['uniqueIds'].last).destroy
          count -= 1
        end
      end
    end
  end
end
