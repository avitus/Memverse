class AddRemainingThreddedPostsIndexes < ActiveRecord::Migration[7.1]
  def up
    # Check existing indexes before adding new ones
    existing_indexes = ActiveRecord::Base.connection.indexes('thredded_posts').map(&:name)

    # Add index for postable association
    unless existing_indexes.include?('index_thredded_posts_on_postable_id')
      add_index :thredded_posts, :postable_id,
                name: 'index_thredded_posts_on_postable_id'
    end

    # Add index for messageboard filtering
    unless existing_indexes.include?('index_thredded_posts_on_messageboard_id')
      add_index :thredded_posts, :messageboard_id,
                name: 'index_thredded_posts_on_messageboard_id'
    end

    # Composite index for moderation display (most important for performance)
    unless existing_indexes.include?('index_thredded_posts_for_display')
      add_index :thredded_posts, [:moderation_state, :updated_at],
                name: 'index_thredded_posts_for_display',
                order: { updated_at: :desc }
    end

    # Index for chronological post ordering within topics
    unless existing_indexes.include?('index_thredded_posts_on_postable_id_and_created_at')
      add_index :thredded_posts, [:postable_id, :created_at],
                name: 'index_thredded_posts_on_postable_id_and_created_at'
    end

    # Add other potentially missing indexes
    unless existing_indexes.include?('index_thredded_posts_on_moderation_state')
      add_index :thredded_posts, :moderation_state,
                name: 'index_thredded_posts_on_moderation_state'
    end

    unless existing_indexes.include?('index_thredded_posts_on_user_id')
      add_index :thredded_posts, :user_id,
                name: 'index_thredded_posts_on_user_id'
    end

    # Log what was done
    Rails.logger.info "Thredded posts indexes after migration: #{ActiveRecord::Base.connection.indexes('thredded_posts').map(&:name).join(', ')}"
  end

  def down
    remove_index :thredded_posts, name: 'index_thredded_posts_on_postable_id', if_exists: true
    remove_index :thredded_posts, name: 'index_thredded_posts_on_messageboard_id', if_exists: true
    remove_index :thredded_posts, name: 'index_thredded_posts_for_display', if_exists: true
    remove_index :thredded_posts, name: 'index_thredded_posts_on_postable_id_and_created_at', if_exists: true
    remove_index :thredded_posts, name: 'index_thredded_posts_on_moderation_state', if_exists: true
    remove_index :thredded_posts, name: 'index_thredded_posts_on_user_id', if_exists: true
  end
end