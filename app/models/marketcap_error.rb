class MarketcapError < StandardError
  # Crea campos que pueden ser accedidos y modificados
  attr_accessor :detail, :status_code, :symbol
  def initialize(message, error_info = {}, symbol = 'NN')
    self.detail = error_info[:message]
    self.status_code = error_info[:status]
    self.symbol = symbol
    super(message)
  end
end
