module API
  module V1
    class ProgressReport < Grape::API
      
      include API::V1::Defaults

      resource :progress_reports do

		# GET /progress_reports
        desc "Return progress_reports for a user"

        get "" do
    	  progress = current_resource_owner.progress_reports
    	  progress.page( params[:page] )
        end

      end # resource definition
  	end # class
  end # module: V1
end # module: API