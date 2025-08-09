class RemoveDuplicateTags < ActiveRecord::Migration[7.0]
  def change
    ActsAsTaggableOn::Tagging.where(:tagger_id => nil).destroy_all
  end
end
