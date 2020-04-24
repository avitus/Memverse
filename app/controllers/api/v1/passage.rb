module API
  module V1
    class Passage < Grape::API
      
      include API::V1::Defaults

      resource :passages do

		    # GET /passages
        desc "Return list of translations"

        get "" do
          passages = current_resource_owner.passages.order(:book_index, :chapter, :first_verse)
          passages.page( params[:page] )
        end

        # GET /passage/:id
        desc "Return a passage"
        params do
          requires :id, type: String, desc: "ID of the passage"
        end
        get ":id" do
          @passage
        end

        # DELETE /passages/1
        desc "Delete a passage"
        params do
          requires :id, type: String, desc: "ID of the passage"
        end
        delete ":id" do
          if !passage
            error! :bad_request, metadata: {reason: 'Could not find passage'}
          elsif !passage.remove
            error! :bad_request, metadata: {reason: 'Passage could not be destroyed'}
          else
            head :no_content
          end
        end

      end # resource definition

      private

    	def passage
    		if current_resource_owner
    		  @passage ||= current_resource_owner.passages.find( params[:id] )
    		else
    		  error! :bad_request, metadata: {reason: 'No current resource owner has been authenticated'}
    		end
      end
      
  	end # class
  end # module: V1
end # module: API




