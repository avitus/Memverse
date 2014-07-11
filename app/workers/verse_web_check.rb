class VerseWebCheck
  include Sidekiq::Worker

  def perform(id)
    vs = Verse.find(id)

    if vs.web_text == vs.database_text
      vs.update_column(:verified, true)
    end
  end
end
