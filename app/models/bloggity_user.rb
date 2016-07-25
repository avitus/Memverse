# Bloggity settings
module BloggityUser
  # Display name
  #
  # @return [String]
  def display_name
    self.name || self.login
  end

  # Can user post to given blog?
  #
  # @param blog_id [Fixnum, nil]
  # @return [Boolean]
  def can_blog?(blog_id = nil)
    self.has_role?("blogger") or self.admin?
  end

  # Can user moderate the comments for a given blog?
  #
  # @param blog_id [Fixnum, nil]
  # @return [Boolean]
  def can_moderate_blog_comments?(blog_id = nil)
    self.admin?
  end

  # Are user's comments on given blog automatically approved?
  # If not, they will be queued until a moderator approves them
  #
  # @param blog_id [Fixnum, nil]
  # @return [Boolean]
  def blog_comment_auto_approved?(blog_id = nil)
    self.memverses.learning.count > 10  or self.completed_sessions >= 5
  end

  # Can user comment on given blog?
  #
  # @param blog_id [Fixnum, nil]
  # @return [Boolean]
  def can_comment?(blog_id = nil)
  	self.completed_sessions >= 2 or self.admin? # We need this to control the spammers
  end

  # Can user create, edit and destroy blogs?
  #
  # @return [Boolean]
  def can_modify_blogs?
    self.admin?
  end

  def user_signed_in?
    true
  end

  # Path to user's avatar, using Gravatar
  def blog_avatar_url
    if(self.respond_to?(:email))
      downcased_email_address = self.email.downcase
      hash = Digest::MD5::hexdigest(downcased_email_address)
      "https://www.gravatar.com/avatar/#{hash}?d=wavatar"
    else
      "https://www.pistonsforum.com/images/avatars/avatar22.gif"
    end
  end
end
