class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    #
    # Note: all available roles are in Role table.
    #

    user ||= User.new # guest user

    can :manage, :all                 if user.has_role?("admin")

    can :manage, ChatChannel          if user.has_role?("admin")

    can :manage, Bloggity::BlogPost   if user.has_role?("blogger")
    can :manage, Verse                if user.has_role?("scribe")

    can :manage, [Quiz, QuizQuestion] if user.has_role?("quizmaster")

    can :manage, QuizQuestion, submitted_by: user.id

    can :create, QuizQuestion # anyone can

    if user.has_role?("moderator")
      can :manage, Bloggity::BlogComment

      can :manage, Bloggity::BlogComment do |comment|
        comment.try(:user) == user
      end
    end

  end # initialize

end # class
