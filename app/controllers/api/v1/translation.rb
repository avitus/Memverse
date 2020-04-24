module API
  module V1
    class Translation < Grape::API
      
      include API::V1::Defaults

      resource :translations do

		# GET /translations
        desc "Return list of translations"

        get "" do
          Translation.for_api
        end

      end # resource definition
  	end # class
  end # module: V1
end # module: API