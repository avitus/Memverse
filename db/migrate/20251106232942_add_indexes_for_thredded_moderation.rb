class AddIndexesForThreddedModeration < ActiveRecord::Migration[7.1]
  def up
    # Get existing indexes to avoid duplicates
    existing_indexes = ActiveRecord::Base.connection.indexes('thredded_posts').map(&:name)

    # Index for finding posts by user in a topic (used when blocking)
    unless existing_indexes.include?('index_thredded_posts_on_postable_and_user')
      add_index :thredded_posts, [:postable_id, :user_id],
                name: 'index_thredded_posts_on_postable_and_user'
    end

    # Index for finding first post in a topic efficiently
    unless existing_indexes.include?('index_thredded_posts_for_first_post')
      add_index :thredded_posts, [:postable_id, :created_at, :id],
                name: 'index_thredded_posts_for_first_post'
    end

    # Check if thredded_user_details table exists and add indexes if needed
    if ActiveRecord::Base.connection.table_exists?('thredded_user_details')
      user_detail_indexes = ActiveRecord::Base.connection.indexes('thredded_user_details').map(&:name)

      # Index for joining user details efficiently
      unless user_detail_indexes.include?('index_thredded_user_details_on_user_id')
        add_index :thredded_user_details, :user_id,
                  name: 'index_thredded_user_details_on_user_id'
      end

      # Index for filtering by moderation state
      unless user_detail_indexes.include?('index_thredded_user_details_on_moderation_state')
        add_index :thredded_user_details, :moderation_state,
                  name: 'index_thredded_user_details_on_moderation_state'
      end
    end

    # Check if thredded_topics table exists and add index if needed
    if ActiveRecord::Base.connection.table_exists?('thredded_topics')
      topic_indexes = ActiveRecord::Base.connection.indexes('thredded_topics').map(&:name)

      # Index for topic moderation state
      unless topic_indexes.include?('index_thredded_topics_on_moderation_state')
        add_index :thredded_topics, :moderation_state,
                  name: 'index_thredded_topics_on_moderation_state'
      end
    end
  end

  def down
    remove_index :thredded_posts, name: 'index_thredded_posts_on_postable_and_user' if index_exists?(:thredded_posts, [:postable_id, :user_id], name: 'index_thredded_posts_on_postable_and_user')
    remove_index :thredded_posts, name: 'index_thredded_posts_for_first_post' if index_exists?(:thredded_posts, [:postable_id, :created_at, :id], name: 'index_thredded_posts_for_first_post')

    if ActiveRecord::Base.connection.table_exists?('thredded_user_details')
      remove_index :thredded_user_details, name: 'index_thredded_user_details_on_user_id' if index_exists?(:thredded_user_details, :user_id, name: 'index_thredded_user_details_on_user_id')
      remove_index :thredded_user_details, name: 'index_thredded_user_details_on_moderation_state' if index_exists?(:thredded_user_details, :moderation_state, name: 'index_thredded_user_details_on_moderation_state')
    end

    if ActiveRecord::Base.connection.table_exists?('thredded_topics')
      remove_index :thredded_topics, name: 'index_thredded_topics_on_moderation_state' if index_exists?(:thredded_topics, :moderation_state, name: 'index_thredded_topics_on_moderation_state')
    end
  end
end