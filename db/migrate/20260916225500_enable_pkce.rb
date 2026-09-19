# frozen_string_literal: true

class EnablePkce < ActiveRecord::Migration[7.2]
  def change
    add_column :oauth_access_grants, :code_challenge, :string
    add_column :oauth_access_grants, :code_challenge_method, :string
  end
end
