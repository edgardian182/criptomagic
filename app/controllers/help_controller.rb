class HelpController < ApplicationController
  skip_before_action :authenticate_user!

  # GET /help
  def index
    @tab = :help
  end

  # GET /donations
  def donations
    @tab = :help
  end
end
