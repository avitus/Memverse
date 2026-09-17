# frozen_string_literal: true

class RegisterPwaOauthApplication < ActiveRecord::Migration[7.2]
  def up
    PwaOauthApplication.ensure!
  end

  def down
    Doorkeeper::Application.find_by(uid: PwaOauthApplication::UID)&.destroy!
  end
end
