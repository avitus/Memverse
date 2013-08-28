# ----------------------------------------------------------------------------------------------------------
# Sphinx Index
# ----------------------------------------------------------------------------------------------------------
ThinkingSphinx::Index.define :verse, :with => :active_record do
  # fields
  indexes translation, :sortable => true
  indexes text
  indexes [book, chapter, versenum], :as => :reference

  # attributes
  has created_at
end
