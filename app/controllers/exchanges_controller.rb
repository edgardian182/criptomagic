class ExchangesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @exchange = Exchange.find(params[:id])
    @search = @exchange.search_coin(params[:search].upcase) if params[:search]
  end
end
