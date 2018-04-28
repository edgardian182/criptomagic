class CoinsController < ApplicationController
  def show
    @coin = Coin.find(params[:id])
  end
end
