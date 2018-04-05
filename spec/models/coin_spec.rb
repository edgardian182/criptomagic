require 'rails_helper'

RSpec.describe Coin, type: :model do
  let(:exchange) do
    Binance.create(name: 'Binance')
  end

  let(:exchange2) do
    Exchange.create(name: 'Bittrex')
  end

  let(:coin) do
    Coin.create(symbol: 'TRX', exchange: exchange)
  end

  before(:each) do
    coin
  end

  # - validations
  describe 'new coin validations' do
    it "should be valid with a SYMBOL and EXCHANGE" do
      new_c = Coin.new(symbol: 'ADA', exchange: exchange)
      expect(new_c).to be_valid
    end

    it 'should be unique in each exchange' do
      # Ya cree TRX en el before
      new_c = Coin.new(symbol: 'TRX', exchange: exchange)
      new_c.valid?
      expect(new_c).not_to be_valid
      expect(new_c.errors[:symbol]).to include("ya existe para #{exchange.name}")

      new_c = Coin.new(symbol: 'TRX', exchange: exchange2) # For exchange 2
      expect(new_c).to be_valid
    end
  end

  # - methods
  describe '#create_candle' do
    it "should create a new candle" do
      expect_any_instance_of(Binance).to receive(:last_candle_for).with(coin.symbol, 15, Time.local(2018,3,30,17)).and_return(
        bought: "10 BTC",
        sold: "20 BTC",
        range: '15m',
        volume: 10,
        init_price: '0.1',
        last_price: '0.2',
        max_price: '0.2',
        min_price: '0.09',
        price_movement: "100%",
        open_time: Time.local(2018,3,30,17) - 15.minutes,
        close_time: Time.local(2018,3,30,17),
        trades: 300,
        symbol: 'TRX'
      )

      coin.create_candle('15m', Time.local(2018,3,30,17))
      expect(coin.candles.count).to eq(1)
    end
  end

  describe '#create_candlestick' do
    it "should create a new candle" do
      expect_any_instance_of(Binance).to receive(:candlestick_for).with(coin.symbol, 1, '15m', Time.local(2018,3,30,17)).and_return(
        [
          {
            bought: "10 BTC",
            sold: "20 BTC",
            range: '15m',
            volume: 10,
            init_price: '0.1',
            last_price: '0.2',
            max_price: '0.2',
            min_price: '0.09',
            price_movement: "100%",
            open_time: Time.local(2018,3,30,17) - 15.minutes,
            close_time: Time.local(2018,3,30,17),
            trades: 300,
            symbol: 'TRX',
            closed: true
          }
        ]
      )

      coin.create_candlestick('15m', Time.local(2018,3,30,17))
      expect(coin.candles.count).to eq(1)
    end
  end

end
