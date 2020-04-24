module API
  module V1
    class Verse < Grape::API
      
      include API::V1::Defaults

      resource :verses do

		    # GET /verses/:id
        desc "Return a verse"
        params do
          requires :id, type: String, desc: "ID of the verse"
        end
        get ":id" do
          Verse.where(id: permitted_params[:id]).first! 
        end

        # GET /verses/lookup
        desc "Return a verse based on the reference"
        params do
          requires :bk, type: String, desc: "Book name"
          requires :ch, type: Integer, desc: "Chapter"
          requires :vs, type: Integer, desc: "Verse"
          optional :tl, type: String, desc: "Translation"          
        end
        get "lookup" do
    	  tl = params[:tl] ? params[:tl] : current_resource_owner.translation
    	  Verse.exists_in_db(params[:bk], params[:ch], params[:vs], tl)        	
        end

        # GET /verses/chapter
        desc "Return entire chapter based on the reference"
        params do
          requires :bk, type: String, desc: "Book name"
          requires :ch, type: Integer, desc: "Chapter"
          requires :vs, type: Integer, desc: "Verse"
          optional :tl, type: String, desc: "Translation"          
        end
        get "chapter" do
    	  tl = params[:tl] ? params[:tl] : current_resource_owner.translation
    	  Verse.where(book: params[:bk], chapter: params[:ch], translation: tl).page( params[:page] )	
        end

        # GET /verses/search
        desc "Return all verses that match search criteria"
        params do
          requires :bk, type: String, desc: "Book name"
          requires :ch, type: Integer, desc: "Chapter"
          requires :vs, type: Integer, desc: "Verse"
          optional :tl, type: String, desc: "Translation"          
        end
        get "search" do
          search_text = params[:searchParams]
          verses = Array.new
    	  verses = Verse.search( Riddle::Query.escape(search_text[0..255]) ) if search_text
        end

      end # resource definition
  	end # class
  end # module: V1
end # module: API



# -- Old RocketPants solution below ------


  # Scopes
  # before_action only: [:show, :lookup, :chapter, :search] do
  #   doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  # end

  # version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  # caches :index, :show, :caches_for => 15.minutes

  # GET /verses/{ID}
  # def show
  #   expose Verse.find( params[:id] )
  # end



  # GET /verses/chapter
  # def chapter
  #   tl = params[:tl] ? params[:tl] : current_resource_owner.translation
  #   expose Verse.where(book: params[:bk], chapter: params[:ch], translation: tl).page( params[:page] )
  # end  

  # GET /verses/search
  # def search
  #   search_text = params[:searchParams]
  #   verses = Array.new
  #   verses = Verse.search( Riddle::Query.escape(search_text[0..255]) ) if search_text
  #   expose verses
  # end