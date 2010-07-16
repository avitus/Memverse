class TagController < ApplicationController
  
  # GET /verses/1/edit
  def edit_tag
    @tag = Tag.find(params[:id])
  end
  
  # PUT /verses/1
  # PUT /verses/1.xml
  def update_tag
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Tag was successfully updated.'
        format.html { redirect_to(show_tags_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end  
  
  # DELETE /verses/1
  # DELETE /verses/1.xml
  def destroy_tag
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(show_tags_url) }
      format.xml  { head :ok }
    end
  end  
  
  
end