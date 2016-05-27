require 'rubygems'
require 'bundler'

Bundler.require :default, :development

Combustion.initialize! :active_record do
  if ENV['RACK_ENV'] == 'development'
    config.assets.debug = true
  end
end

if ENV['RACK_ENV'] == 'development'
  User.create! :name => "Lucia",
               :last_name => "Napoli",
               :email => "lucianapoli@gmail.com",
               :height => "h51",
               :address => "Via Roma 99",
               :zip => "25123",
               :country => "2",
               :receive_email => false,
               :birth_date => Time.now.utc,
               :money => 100,
               :money_proc => 100,
               :favorite_color => 'Red',
               :favorite_books => "The City of Gold and Lead",
               :description => "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus a lectus et lacus ultrices auctor. Morbi aliquet convallis tincidunt. Praesent enim libero, iaculis at commodo nec, fermentum a dolor. Quisque eget eros id felis lacinia faucibus feugiat et ante. Aenean justo nisi, aliquam vel egestas vel, porta in ligula. Etiam molestie, lacus eget tincidunt accumsan, elit justo rhoncus urna, nec pretium neque mi et lorem. Aliquam posuere, dolor quis pulvinar luctus, felis dolor tincidunt leo, eget pretium orci purus ac nibh. Ut enim sem, suscipit ac elementum vitae, sodales vel sem.",
               :favorite_movie => "The Hitchhiker's Guide to the Galaxy"
end
run Combustion::Application

