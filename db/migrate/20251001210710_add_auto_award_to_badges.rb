class AddAutoAwardToBadges < ActiveRecord::Migration[7.1]
  def change
    add_column :badges, :auto_award, :boolean, default: true, null: false

    # Quiz Champion should only be awarded by winning a quiz, not through badge completion checks
    reversible do |dir|
      dir.up do
        Badge.where(name: 'Quiz Champion').update_all(auto_award: false)
      end
    end
  end
end
