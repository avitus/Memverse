class RemoveDuplicateTags < ActiveRecord::Migration
  def change
    ActsAsTaggableOn::Tagging.where(:tagger_id => nil).destroy_all
  end
end
