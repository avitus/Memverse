require 'spec_helper_integration'

module Doorkeeper
  describe AccessToken do
    subject { FactoryGirl.build(:access_token) }

    it { should be_valid }

    it_behaves_like "an accessible token"
    it_behaves_like "a revocable token"
    it_behaves_like "an unique token" do
      let(:factory_name) { :access_token }
    end

    describe :refresh_token do
      it 'has empty refresh token if it was not required' do
        token = FactoryGirl.create :access_token
        token.refresh_token.should be_nil
      end

      it 'generates a refresh token if it was requested' do
        token = FactoryGirl.create :access_token, :use_refresh_token => true
        token.refresh_token.should_not be_nil
      end

      it "is not valid if token exists" do
        token1 = FactoryGirl.create :access_token, :use_refresh_token => true
        token2 = FactoryGirl.create :access_token, :use_refresh_token => true
        token2.send :write_attribute, :refresh_token, token1.refresh_token
        token2.should_not be_valid
      end

      it 'expects database to raise an error if refresh tokens are the same' do
        token1 = FactoryGirl.create :access_token, :use_refresh_token => true
        token2 = FactoryGirl.create :access_token, :use_refresh_token => true
        expect {
          token2.write_attribute :refresh_token, token1.refresh_token
          token2.save(:validate => false)
        }.to raise_error
      end
    end

    describe "validations" do
      it "is valid without resource_owner_id" do
        # For client credentials flow
        subject.resource_owner_id = nil
        should be_valid
      end

      it "is invalid without application_id" do
        subject.application_id = nil
        should_not be_valid
      end
    end

    describe '.revoke_all_for' do
      let(:resource_owner) { stub(:id => 100) }
      let(:application)    { FactoryGirl.create :application }
      let(:default_attributes) do
        { :application => application, :resource_owner_id => resource_owner.id }
      end

      it 'revokes all tokens for given application and resource owner' do
        FactoryGirl.create :access_token, default_attributes
        AccessToken.revoke_all_for application.id, resource_owner
        AccessToken.all.should be_empty
      end

      it 'matches application' do
        FactoryGirl.create :access_token, default_attributes.merge(:application => FactoryGirl.create(:application))
        AccessToken.revoke_all_for application.id, resource_owner
        AccessToken.all.should_not be_empty
      end

      it 'matches resource owner' do
        FactoryGirl.create :access_token, default_attributes.merge(:resource_owner_id => 90)
        AccessToken.revoke_all_for application.id, resource_owner
        AccessToken.all.should_not be_empty
      end
    end

    describe '.matching_token_for' do
      let(:resource_owner_id) { 100 }
      let(:application)       { FactoryGirl.create :application }
      let(:scopes)            { Doorkeeper::OAuth::Scopes.from_string("public write") }
      let(:default_attributes) do
        { :application => application, :resource_owner_id => resource_owner_id, :scopes => scopes.to_s }
      end

      it 'returns only one token' do
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should == token
      end

      it 'accepts resource owner as object' do
        resource_owner = stub(:to_key => true, :id => 100)
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner, scopes)
        last_token.should == token
      end

      it 'accepts nil as resource owner' do
        token = FactoryGirl.create :access_token, default_attributes.merge(:resource_owner_id => nil)
        last_token = AccessToken.matching_token_for(application, nil, scopes)
        last_token.should == token
      end

      it 'excludes revoked tokens' do
        FactoryGirl.create :access_token, default_attributes.merge(:revoked_at => 1.day.ago)
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should be_nil
      end

      it 'matches the application' do
        token = FactoryGirl.create :access_token, default_attributes.merge(:application => FactoryGirl.create(:application))
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should be_nil
      end

      it 'matches the resource owner' do
        FactoryGirl.create :access_token, default_attributes.merge(:resource_owner_id => 2)
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should be_nil
      end

      it 'matches the scopes' do
        FactoryGirl.create :access_token, default_attributes.merge(:scopes => 'public email')
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should be_nil
      end

      it 'returns the last created token' do
        FactoryGirl.create :access_token, default_attributes.merge(:created_at => 1.day.ago)
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        last_token.should == token
      end

      it 'returns as_json hash'   do
        token = FactoryGirl.create :access_token, default_attributes
        token_hash = {
                      :resource_owner_id => token.resource_owner_id,
                      :scopes => token.scopes,
                      :expires_in_seconds => token.expires_in_seconds, 
                      :application => { :uid => token.application.uid }
                     }
        token.as_json.should eq token_hash
      end
    end

  end
end
