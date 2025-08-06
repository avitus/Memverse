require 'spec_helper'

describe Ability do
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(user) }

  describe "initialization" do
    it "initializes with a user" do
      expect(ability).to be_an_instance_of(Ability)
    end

    it "handles nil user as guest user" do
      guest_ability = Ability.new(nil)
      expect(guest_ability).to be_an_instance_of(Ability)
    end
  end

  describe "admin permissions" do
    let(:admin_role) { FactoryBot.create(:role, name: "admin") }
    let(:admin_user) { FactoryBot.create(:user) }

    before do
      admin_user.roles << admin_role
    end

    it "grants admin users permission to manage all resources" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, :all)).to be true
    end

    it "grants admin users permission to manage ChatChannel" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, ChatChannel)).to be true
    end

    it "does not grant non-admin users permission to manage all" do
      expect(ability.can?(:manage, :all)).to be false
    end
  end

  describe "blogger permissions" do
    let(:blogger_role) { FactoryBot.create(:role, name: "blogger") }
    let(:blogger_user) { FactoryBot.create(:user) }

    before do
      blogger_user.roles << blogger_role
    end

    it "grants blogger users permission to manage blog posts" do
      blogger_ability = Ability.new(blogger_user)
      expect(blogger_ability.can?(:manage, Bloggity::BlogPost)).to be true
    end

    it "does not grant non-blogger users permission to manage blog posts" do
      expect(ability.can?(:manage, Bloggity::BlogPost)).to be false
    end
  end

  describe "scribe permissions" do
    let(:scribe_role) { FactoryBot.create(:role, name: "scribe") }
    let(:scribe_user) { FactoryBot.create(:user) }

    before do
      scribe_user.roles << scribe_role
    end

    it "grants scribe users permission to manage verses" do
      scribe_ability = Ability.new(scribe_user)
      expect(scribe_ability.can?(:manage, Verse)).to be true
    end

    it "does not grant non-scribe users permission to manage verses" do
      expect(ability.can?(:manage, Verse)).to be false
    end
  end

  describe "quizmaster permissions" do
    let(:quizmaster_role) { FactoryBot.create(:role, name: "quizmaster") }
    let(:quizmaster_user) { FactoryBot.create(:user) }

    before do
      quizmaster_user.roles << quizmaster_role
    end

    it "grants quizmaster users permission to manage quizzes" do
      quizmaster_ability = Ability.new(quizmaster_user)
      expect(quizmaster_ability.can?(:manage, Quiz)).to be true
    end

    it "grants quizmaster users permission to manage quiz questions" do
      quizmaster_ability = Ability.new(quizmaster_user)
      expect(quizmaster_ability.can?(:manage, QuizQuestion)).to be true
    end

    it "does not grant non-quizmaster users permission to manage quizzes" do
      expect(ability.can?(:manage, Quiz)).to be false
    end
  end

  describe "quiz question ownership permissions" do
    let(:quiz) { FactoryBot.create(:quiz, user: user) }
    let(:quiz_question) { FactoryBot.create(:quiz_question, quiz: quiz, submitted_by: user.id) }
    let(:other_user) { FactoryBot.create(:user) }
    let(:other_quiz) { FactoryBot.create(:quiz, user: other_user) }
    let(:other_quiz_question) { FactoryBot.create(:quiz_question, quiz: other_quiz, submitted_by: other_user.id) }

    it "allows users to manage their own quiz questions" do
      expect(ability.can?(:manage, quiz_question)).to be true
    end

    it "does not allow users to manage other users' quiz questions" do
      other_ability = Ability.new(other_user)
      expect(other_ability.can?(:manage, quiz_question)).to be false
    end
  end

  describe "quiz question creation permissions" do
    it "allows any user to create quiz questions" do
      expect(ability.can?(:create, QuizQuestion)).to be true
    end

    it "allows guest users to create quiz questions" do
      guest_ability = Ability.new(nil)
      expect(guest_ability.can?(:create, QuizQuestion)).to be true
    end
  end

  describe "moderator permissions" do
    let(:moderator_role) { FactoryBot.create(:role, name: "moderator") }
    let(:moderator_user) { FactoryBot.create(:user) }

    before do
      moderator_user.roles << moderator_role
    end

    it "grants moderator users permission to manage blog comments" do
      moderator_ability = Ability.new(moderator_user)
      expect(moderator_ability.can?(:manage, Bloggity::BlogComment)).to be true
    end

    it "does not grant non-moderator users permission to manage blog comments" do
      expect(ability.can?(:manage, Bloggity::BlogComment)).to be false
    end
  end

  describe "guest user permissions" do
    let(:guest_ability) { Ability.new(nil) }

    it "allows guest users to create quiz questions" do
      expect(guest_ability.can?(:create, QuizQuestion)).to be true
    end

    it "does not allow guest users to manage resources" do
      expect(guest_ability.can?(:manage, :all)).to be false
      expect(guest_ability.can?(:manage, Verse)).to be false
      expect(guest_ability.can?(:manage, Quiz)).to be false
    end
  end

  describe "role inheritance" do
    let(:admin_role) { FactoryBot.create(:role, name: "admin") }
    let(:blogger_role) { FactoryBot.create(:role, name: "blogger") }
    let(:admin_user) { FactoryBot.create(:user) }

    before do
      admin_user.roles << admin_role
    end

    it "admin users inherit blogger permissions" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, Bloggity::BlogPost)).to be true
    end

    it "admin users inherit scribe permissions" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, Verse)).to be true
    end

    it "admin users inherit quizmaster permissions" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, Quiz)).to be true
      expect(admin_ability.can?(:manage, QuizQuestion)).to be true
    end

    it "admin users inherit moderator permissions" do
      admin_ability = Ability.new(admin_user)
      expect(admin_ability.can?(:manage, Bloggity::BlogComment)).to be true
    end
  end
end