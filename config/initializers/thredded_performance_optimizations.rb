# frozen_string_literal: true

# Performance optimization for Thredded forum.
#
# The default preload_first_topic_post scope in Thredded::PostCommon runs a
# MAX() subquery per topic, producing O(N) subqueries on the moderation page.
# Since first-post data is not needed for moderation display, we replace it
# with a no-op.

Rails.application.config.after_initialize do
  if defined?(Thredded::PostCommon)
    module Thredded
      module PostCommon
        module ClassMethods
          def preload_first_topic_post
            all
          end
        end
      end
    end
  end
end
