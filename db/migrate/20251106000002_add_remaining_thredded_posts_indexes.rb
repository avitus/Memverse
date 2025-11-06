class AddRemainingThreddedPostsIndexes < ActiveRecord::Migration[7.1]
  def change
    # Add remaining missing indexes that weren't created in the previous migration

    # Add index for postable association
    add_index :thredded_posts, :postable_id,
              name: 'index_thredded_posts_on_postable_id'

    # Add index for messageboard filtering
    add_index :thredded_posts, :messageboard_id,
              name: 'index_thredded_posts_on_messageboard_id'

    # Composite index for moderation display (most important for performance)
    add_index :thredded_posts, [:moderation_state, :updated_at],
              name: 'index_thredded_posts_for_display',
              order: { updated_at: :desc }

    # Index for chronological post ordering within topics
    add_index :thredded_posts, [:postable_id, :created_at],
              name: 'index_thredded_posts_on_postable_id_and_created_at'
  end
end