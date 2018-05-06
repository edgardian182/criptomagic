class ExchangesController < ApplicationController
  def show
    @exchange = Exchange.find(params[:id])
    @search = @exchange.search_coin(params[:search].upcase) if params[:search]
  end
end
