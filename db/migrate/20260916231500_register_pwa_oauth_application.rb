# frozen_string_literal: true

class RegisterPwaOauthApplication < ActiveRecord::Migration[7.2]
  def up
    PwaOauthApplication.ensure!
  end

  # `up` may have updated an application that existed before this migration,
  # so rolling back must not destroy it. Re-running `up` is idempotent.
  def down; end
end
