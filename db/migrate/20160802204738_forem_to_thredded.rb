# Copy Forem data to Thredded
class ForemToThredded < ActiveRecord::Migration

  def up

    change_column(:friendly_id_slugs, :created_at, :datetime, :null => true)

    skip_callbacks = [
        [Thredded::Post, :create, :after, :update_parent_last_user_and_timestamp],
        [Thredded::PrivatePost, :create, :after, :update_parent_last_user_and_timestamp],
        [Thredded::Post, :commit, :after, :auto_follow_and_notify],
        [Thredded::PrivatePost, :commit, :after, :notify_users],
    ]
    begin
      # Disable all timestamp handling
      ActiveRecord::Base.record_timestamps = false
      # Disable callbacks to avoid creating notifications and performing unnecessary updates
      skip_callbacks.each { |(klass, *args)| klass.skip_callback(*args) }
      ActiveRecord::Base.no_touching do
        transaction do
          copy_data
        end
      end
    ensure
      # Re-enable timestamp handling
      ActiveRecord::Base.record_timestamps = true
      # Re-enable callbacks
      skip_callbacks.each { |(klass, *args)| klass.set_callback(*args) }
    end
  end

  def down
	
	change_column(:friendly_id_slugs, :created_at, :datetime, :null => false)

    rename_column Thredded.user_class.table_name, :thredded_admin, :forem_admin
    [Thredded::Messageboard, Thredded::MessageboardGroup, Thredded::Topic, Thredded::Post,
     Thredded::UserTopicFollow, Thredded::UserDetail].each do |klass|
      say "Deleting #{klass.name}..."
      klass.delete_all
    end
  end

  private

  def copy_data
    forem_data = %i(
        groups memberships moderator_groups
        posts subscriptions topics views
      ).inject({}) { |h, k|
      h.update k => connection.select_all("SELECT * FROM forem_#{k}")
    }
    %i(categories forums).each { |t|
      forem_data[t] = connection.select_all("SELECT * FROM forem_#{t} ORDER BY position")
    }
    now = Time.zone.now

    say 'Creating UserDetails...'
    moderation_states = Hash[Thredded.user_class.pluck(:id, :forem_state)]
    user_details = forem_data[:posts].group_by { |p| p['user_id'] }.map do |user_id, user_posts|
      Thredded::UserDetail.create!(
          user_id:            user_id,
          latest_activity_at: user_posts.max_by { |p| p['created_at'] }['created_at'],
          created_at:         now,
          updated_at:         now,
          moderation_state:   thredded_moderation_state(moderation_states[user_id]))
    end
    say "Created #{user_details.length} UserDetails"

    say 'Copying Forem Categories to Messageboard Groups'
    messageboard_groups = forem_data[:categories].inject({}) { |h, c|
      h.update(
          c['id'] => Thredded::MessageboardGroup.create!(
              name: c['name'],
              created_at: now,
              updated_at: now
          )
      )
    }
    say 'Copying Messageboards...'
    boards = forem_data[:forums].inject({}) { |h, f|
      h.update(
          f['id'] => Thredded::Messageboard.create!(
              name:        f['name'],
              description: f['description'],
              slug:        f['slug'],
              messageboard_group_id: messageboard_groups[f['category_id']].try(:id),
              created_at:  now,
              updated_at:  now
          )
      )
    }
    say "Created #{boards.size} Messageboards"

    say 'Copying Topics...'
    forem_posts_by_topic = forem_data[:posts].group_by { |p| p['topic_id'] }
    topics = forem_data[:topics].inject({}) { |h, t|
      last_post = forem_posts_by_topic[t['id']].max_by { |p| p['created_at'] }
      h.update(
          t['id'] => Thredded::Topic.create!(
              messageboard_id:  boards[t['forum_id']].id,
              user_id:          t['user_id'],
              title:            t['subject'],
              slug:             t['slug'],
              sticky:           t['pinned'],
              locked:           t['locked'],
              created_at:       t['created_at'],
              updated_at:       last_post['created_at'],
              last_user_id:     last_post['user_id'],
              moderation_state: thredded_moderation_state(t['state'])
          )
      )
    }
    say "Created #{topics.size} Topics"

    say 'Copying Posts...'
    post_count = 0
    posts = forem_data[:posts].inject({}) { |h, p|
      topic = topics[p['topic_id']]
      if topic
      	  if h
            post_count = post_count + 1
            if post_count % 1000 == 0
              say "#{post_count} posts have been copied to Thredded format"
            end
		        h.update(
		          p['id'] => Thredded::Post.create!(
		              user_id:          p['user_id'],
		              messageboard_id:  topic.messageboard_id,
		              postable_id:      topic.id,
		              created_at:       p['created_at'],
		              updated_at:       p['updated_at'],
		              content:          p['text'],
		              moderation_state: thredded_moderation_state(p['state'])
		        )
		      ) 
		  else
		  	say "  - Error: Encountered a nil h topic"
		  end
  	  else
  	  	say "  - Error: Topic with ID #{p['topic_id']} is nil."
  	  end
    }
    say "Created #{posts.size} Posts"

    say 'Creating Forem Subscriptions to UserTopicFollows...'
    subs_count = 0
    forem_data[:subscriptions].each do |sub|
      topic = topics[sub['topic_id']]
      next unless topic
      Thredded::UserTopicFollow.create!(
          user_id:  sub['subscriber_id'],
          topic_id: topic.id,
          reason: :manual,
          created_at: now
      )
      subs_count += 1
    end
    say "Created #{subs_count} UserTopicFollows..."

    say 'Updating counters'
    boards.each { |_k, v| Thredded::Messageboard.reset_counters(v.id, :topics, :posts) }
    topics.each { |_k, v| Thredded::Topic.reset_counters(v.id, :posts) }
    user_details.each { |v| Thredded::UserDetail.reset_counters(v.id, :topics, :posts) }

    rename_column Thredded.user_class.table_name, :forem_admin, :thredded_admin
  end

  THREDDED_MODERATION_STATES = {
      'pending_moderation' => :pending_moderation,
      'approved'           => :approved,
      'spam'               => :blocked,
  }.freeze

  def thredded_moderation_state(forem_moderation_state)
    THREDDED_MODERATION_STATES[forem_moderation_state] || :pending_moderation
  end
end
