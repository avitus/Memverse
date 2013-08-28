ThinkingSphinx::Index.define 'bloggity/blog_post', :with => :active_record do
  # fields
  indexes title, :sortable => true
  indexes body
  indexes posted_by.name, :as => :author, :sortable => true

  # attributes
  has posted_by_id, created_at, updated_at
end
