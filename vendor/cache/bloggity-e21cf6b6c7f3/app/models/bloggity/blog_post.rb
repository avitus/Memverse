# == Schema Information
# Schema version: 20090406223746
#
# Table name: blog_posts
#
#  id              :integer(4)      not null, primary key
#  title           :string(255)
#  body            :text
#  is_indexed      :boolean(1)
#  tag_string      :string(255)
#  posted_by_id    :integer(4)
#  is_complete     :boolean(1)
#  created_at      :datetime
#  updated_at      :datetime
#  url_identifier  :string(255)
#  comments_closed :boolean(1)
#  category_id     :integer(4)
#  fck_created     :boolean(1)
#  blog_id         :integer(4)
#

module Bloggity
class BlogPost < ActiveRecord::Base

  include Bloggity::ApplicationHelper

  belongs_to :posted_by, :class_name => 'User'
  belongs_to :category, :class_name => 'BlogCategory'
  has_many :comments, :class_name => 'BlogComment'
  has_many :approved_comments, -> { where approved: true }, :class_name => 'BlogComment'
  has_many :assets, :class_name => 'BlogAsset'
  has_many :tags, :class_name => 'BlogTag'
  belongs_to :blog

  validates_presence_of :blog_id, :posted_by_id
  validate :authorized_to_blog?
#   validates :url_identifier, :uniqueness => true

  # Recommended... but only if you have it:
  # xss_terminate :except => [ :body ]
  after_save :save_tags
  before_save :update_url_identifier, :tweet_public_publish

  def comments_closed?
    self.comments_closed
  end

  # --------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------
  private
  # --------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------

  def update_url_identifier
    # We won't update URL identifier if there's no title, or if this blog was already published
    # with a URL identifier (don't want to break links)
    return if self.title.blank? || (self.is_complete && !self.url_identifier.blank?)

    url_identifier = self.title.parameterize
    x = 0

    while BlogPost.where("url_identifier = ? and id != ?", url_identifier, self.id).first do
      x += 1
      url_identifier = self.title.parameterize + "--" + x.to_s
    end

    self.url_identifier = url_identifier

    true
  end

  def authorized_to_blog?
    unless(self.posted_by && self.posted_by.can_blog?(self.blog_id))
      self.errors.add(:posted_by_id, "is not authorized to post to this blog")
    end
  end

  def save_tags
    return if self.tag_string.blank?
    BlogTag.delete_all(["blog_post_id = ?", self.id])
    these_tags = self.tag_string.split(",")
    these_tags.each do |tag|
      sanitary_tag = tag.strip.chomp
      BlogTag.create(:name => sanitary_tag, :blog_post_id => self.id)
    end
  end

  def tweet_public_publish # Note: this must be called before_save or else the tweeted attribute will not update.
    if self.is_complete? && !self.tweeted?
      link = "<a href=\"#{blog_named_link(self)}\">#{self.title}</a>"
      Tweet.create(:news => "#{self.posted_by.name_or_login} wrote a new blog post: '#{link}'", :user_id => self.posted_by_id, :importance => 2)
      self.tweeted = true
    end
  end

end
end
