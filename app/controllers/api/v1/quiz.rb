module API
  module V1
    class Quiz < Grape::API
      
      include API::V1::Defaults

      resource :quizzes do

		# GET /quizzes
        desc "Return list of all quizzes"
        get "" do
          Quiz.all
        end

        # GET /quiz
		get "show"
		  @quiz
		end

		# GET /upcoming
		get "upcoming"
		  @quiz
		end

      end # resource definition

	  private

	  def quiz
	    @quiz ||= Quiz.find( params[:id] || 1 )
	  end

  	end # class
  end # module: V1
end # module: API



