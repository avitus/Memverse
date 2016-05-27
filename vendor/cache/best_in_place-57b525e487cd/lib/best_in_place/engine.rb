module BestInPlace
  class Engine < Rails::Engine
    initializer 'best_in_place' do
      ActionView::Base.send(:include, BestInPlace::Helper)
      ActionController::Base.send(:include, BestInPlace::ControllerExtensions)
    end
  end
end
