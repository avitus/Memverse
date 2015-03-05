class User < ActiveRecord::Base
  include Forem::DefaultPermissions
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable

  def to_s
    fail # to_s should not be called in tests
  end

  def forem_name
    login
  end

end
