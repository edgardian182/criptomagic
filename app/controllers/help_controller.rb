class HelpController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @tab = :help
  end
end
