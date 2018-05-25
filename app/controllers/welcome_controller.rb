class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @exchanges = Exchange.all
    render layout: "launch_page"
  end
end
