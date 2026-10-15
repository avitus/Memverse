# frozen_string_literal: true

require 'rails_helper'

# MEMVERSE-9M: logins are generated from the name, which may be 60 characters,
# but the users.login column only holds 40, so long names raised
# ActiveRecord::ValueTooLong during signup.
RSpec.describe User, 'login' do
  # 60 characters: the longest name the name validation accepts
  let(:long_name) { 'Bartholomew Maximilian Montgomery-Fitzgerald, of Westminster' }

  it 'caps login length at the users.login column limit' do
    expect(User::LOGIN_MAX_LENGTH).to eq(User.columns_hash['login'].limit)
  end

  it 'accepts a login at the column limit' do
    expect(FactoryBot.build(:user, login: 'a' * User::LOGIN_MAX_LENGTH)).to be_valid
  end

  it 'rejects a login longer than the column allows' do
    user = FactoryBot.build(:user, login: 'a' * (User::LOGIN_MAX_LENGTH + 1))

    expect(user).not_to be_valid
    expect(user.errors[:login]).to be_present
  end

  describe 'generated from the name' do
    it 'fits a login generated from the longest allowed name into the column' do
      expect(long_name.length).to eq(60)

      user = FactoryBot.create(:user, name: long_name)

      expect(user.reload.login).to eq('bartholomew-maximilian-montgomery-fitzge')
    end

    it 'keeps a de-duplicated login within the column' do
      first  = FactoryBot.create(:user, name: long_name)
      second = FactoryBot.create(:user, name: long_name)

      expect(second.reload.login).to eq('bartholomew-maximilian-montgomery-fit--2')
      expect(second.login).not_to eq(first.login)
    end

    it 'leaves short generated logins unchanged' do
      expect(FactoryBot.create(:user, name: 'Jane Doe').login).to eq('jane-doe')
    end
  end
end
