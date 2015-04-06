module Forem
  class Post < ActiveRecord::Base
    include Workflow
    include Forem::Concerns::NilUser

    workflow_column :state
    workflow do
      state :pending_review do
        event :spam,    :transitions_to => :spam
        event :approve, :transitions_to => :approved
      end
      state :spam
      state :approved do
        event :approve, :transitions_to => :approved
      end
    end

    # Used in the moderation tools partial
    attr_accessor :moderation_option

    belongs_to :topic
    belongs_to :forem_user, :class_name => Forem.user_class.to_s, :foreign_key => :user_id
    belongs_to :reply_to, :class_name => "Post"

    has_many :replies, :class_name  => "Post",
                       :foreign_key => "reply_to_id",
                       :dependent   => :nullify

    validates :text, :presence => true

    delegate :forum, :to => :topic

    after_create :set_topic_last_post_at
    after_create :subscribe_replier, :if => :user_auto_subscribe?
    after_create :skip_pending_review

    class << self
      def approved
        where(:state => "approved")
      end

      def approved_or_pending_review_for(user)
        if user
          where arel_table[:state].eq('approved').or(
                  arel_table[:state].eq('pending_review').and(arel_table[:user_id].eq(user.id))
                )
        else
          approved
        end
      end

      def by_created_at
        order :created_at
      end

      def pending_review
        where :state => 'pending_review'
      end

      def spam
        where :state => 'spam'
      end

      def visible
        joins(:topic).where(:forem_topics => { :hidden => false })
      end

      def topic_not_pending_review
        joins(:topic).where(:forem_topics => { :state => 'approved'})
      end

      def moderate!(posts)
        posts.each do |post_id, moderation|
          # We use find_by_id here just in case a post has been deleted.
          post = Post.find_by_id(post_id)
          post.send("#{moderation[:moderation_option]}!") if post
        end
      end
    end

    def user_auto_subscribe?
      user && user.respond_to?(:forem_auto_subscribe) && user.forem_auto_subscribe?
    end

    def owner_or_admin?(other_user)
      user == other_user || other_user.forem_admin?
    end

    protected

    def subscribe_replier
      if topic && user
        topic.subscribe_user(user.id)
      end
    end

    # Called when a post is approved.
    def approve
      approve_user
      return if notified?
      email_topic_subscribers
    end

    def email_topic_subscribers
      topic.subscriptions.includes(:subscriber).find_each do |subscription|
        subscription.send_notification(id) if subscription.subscriber != user
      end
      update_column(:notified, true)
    end

    def set_topic_last_post_at
      topic.update_column(:last_post_at, created_at)
    end

    def skip_pending_review
      approve! unless user && user.forem_moderate_posts?
    end

    def approve_user
      user.update_column(:forem_state, "approved") if user && user.forem_state != "approved"
    end

    def spam
      user.update_column(:forem_state, "spam") if user
    end

  end
end
