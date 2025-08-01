class VolunteerController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize! :manage, :all
    
    @specialized_roles = ['scribe', 'blogger', 'admin', 'quizmaster', 'moderator']
    
    @users_by_role = {}
    @specialized_roles.each do |role_name|
      role = Role.find_by(name: role_name)
      @users_by_role[role_name] = role ? role.users.order(:login) : []
    end
  end
end