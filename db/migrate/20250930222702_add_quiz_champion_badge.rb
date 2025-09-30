class AddQuizChampionBadge < ActiveRecord::Migration[7.1]
  def up
    Badge.find_or_create_by(name: 'Quiz Champion') do |badge|
      badge.color = 'solo'
      badge.description = 'Won a weekly Bible knowledge quiz'
    end
  end

  def down
    Badge.where(name: 'Quiz Champion').destroy_all
  end
end
