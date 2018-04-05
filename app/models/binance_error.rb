class BinanceError < StandardError
  # Crea campos que pueden ser accedidos y modificados
  attr_accessor :error_code, :detail, :status_code, :symbol
  def initialize(message, error_info = {}, symbol = 'NN')
    self.error_code = error_info['code']
    self.detail = error_info['msg']
    self.status_code = error_info['status']
    self.symbol = symbol
    super(message)
  end
end
