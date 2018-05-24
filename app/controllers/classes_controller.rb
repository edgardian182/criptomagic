class ClassesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @tab = :classes
  end
end
