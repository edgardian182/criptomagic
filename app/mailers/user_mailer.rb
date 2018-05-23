class UserMailer < ApplicationMailer
  default from: 'criptomagicapp@gmail.com'

  def welcome_email
    @user = params[:user]
    @url = 'www.criptomagicapp.com/users/sign_up'
    mail(to: @user.email, subjetc: 'Welcome to CriptoMagicApp')
  end
end
