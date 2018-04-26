class WelcomeController < ApplicationController
  def index
    @exchanges = Exchange.all
  end
end
