require 'spec_helper'

describe BadgesController do
  include Devise::Test::ControllerHelpers

  describe "GET #badge_completion_check" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in user
    end

    context "with auto_award badges" do
      let!(:badge_with_quest) { FactoryBot.create(:badge, name: 'Test Badge', color: 'bronze', auto_award: true) }
      let!(:quest) { FactoryBot.create(:quest, badge: badge_with_quest, task: 'memorize', objective: 'Verses', quantity: 1) }

      it "awards badge when requirements are met and auto_award is true" do
        # Give user the quest completion
        user.quests << quest

        get :badge_completion_check, format: :json

        expect(response).to be_successful
        expect(user.badges.reload).to include(badge_with_quest)
      end
    end

    context "with non-auto_award badges" do
      let!(:quiz_champion_badge) { FactoryBot.create(:badge, name: 'Quiz Champion', color: 'solo', auto_award: false) }

      it "does not award Quiz Champion badge even if achieved method returns true" do
        # Even with no quests (which would make achieved? return true),
        # the badge should not be awarded because auto_award is false
        get :badge_completion_check, format: :json

        expect(response).to be_successful
        expect(user.badges.reload).not_to include(quiz_champion_badge)
      end

      it "does not check achieved? for non-auto_award badges" do
        # The badge should be skipped entirely
        expect(quiz_champion_badge).not_to receive(:achieved?)

        get :badge_completion_check, format: :json

        expect(response).to be_successful
      end
    end

    context "with multiple badges" do
      let!(:auto_badge1) { FactoryBot.create(:badge, name: 'Auto Badge 1', color: 'bronze', auto_award: true) }
      let!(:quest1) { FactoryBot.create(:quest, badge: auto_badge1, task: 'memorize', objective: 'Verses', quantity: 1) }

      let!(:auto_badge2) { FactoryBot.create(:badge, name: 'Auto Badge 2', color: 'silver', auto_award: true) }
      let!(:quest2) { FactoryBot.create(:quest, badge: auto_badge2, task: 'review', objective: 'Sessions', quantity: 5) }

      let!(:manual_badge) { FactoryBot.create(:badge, name: 'Manual Badge', color: 'gold', auto_award: false) }

      it "only awards auto_award badges" do
        # Give user all quests (which would normally award all badges)
        user.quests << quest1
        user.quests << quest2

        get :badge_completion_check, format: :json

        expect(response).to be_successful
        awarded_badges = user.badges.reload

        expect(awarded_badges).to include(auto_badge1)
        expect(awarded_badges).to include(auto_badge2)
        expect(awarded_badges).not_to include(manual_badge)
      end
    end
  end

  describe "Quiz Champion badge protection" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in user
    end

    it "ensures Quiz Champion badge cannot be awarded through badge_completion_check" do
      # Create the Quiz Champion badge exactly as it would exist in production
      quiz_champion = Badge.create!(
        name: 'Quiz Champion',
        color: 'solo',
        description: 'Won a weekly Bible knowledge quiz',
        auto_award: false
      )

      # Even though the badge has no quests (which would make achieved? return true),
      # it should not be awarded
      get :badge_completion_check, format: :json

      expect(response).to be_successful
      expect(user.badges.reload).not_to include(quiz_champion)

      # The badge should only be awardable through the KnowledgeQuiz worker
      # Simulate what the worker does
      quiz_champion.award_badge(user)
      expect(user.badges.reload).to include(quiz_champion)
    end
  end
end
