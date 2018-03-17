class User
  include Mongoid::Document

  field :username, type: String
  field :password, type: String

  def client
    @client ||= UserClient.new(username, password)
  end
end
