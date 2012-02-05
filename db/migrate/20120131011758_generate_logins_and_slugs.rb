class GenerateLoginsAndSlugs < ActiveRecord::Migration
  def up
    User.find_each(&:save) # Generate logins as needed (since before_save :generate_login in user model)
    AmericanState.find_each(&:save) # This and below will generate slugs
    Country.find_each(&:save)
  end

  def down
  end
end
