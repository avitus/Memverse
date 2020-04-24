module API
  module V1
    class FinalVerse < Grape::API
      
      include API::V1::Defaults

      resource :final_Verses do

		# GET /final_verses
        desc "Return last verse of each Bible book"

        get "" do
          FinalVerse.all.page( params[:page])
        end

      end # resource definition
  	end # class
  end # module: V1
end # module: API