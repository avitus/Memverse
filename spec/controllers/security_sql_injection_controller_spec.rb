require 'spec_helper'

describe "SQL Injection Protection" do
  
  describe MemversesController, type: :controller do
    before(:each) do
      @user = FactoryBot.create(:user)
      @user.confirm
      sign_in @user
    end
    
    describe "GET 'manage_verses'" do
      it "prevents SQL injection in sort_order parameter" do
        # Create test data
        FactoryBot.create(:memverse, user: @user)
        
        # Attempt SQL injection
        malicious_params = [
          "created_at; DELETE FROM users; --",
          "created_at) OR 1=1--",
          "created_at UNION SELECT * FROM users--",
          "); DROP TABLE memverses;--"
        ]
        
        malicious_params.each do |param|
          expect {
            get :manage_verses, params: { sort_order: param }
          }.not_to raise_error
          
          expect(response).to be_successful
          # Verify database integrity
          expect(User.count).to be > 0
          expect(Memverse.count).to be > 0
        end
      end
      
      it "only allows whitelisted sort columns" do
        FactoryBot.create(:memverse, user: @user)
        
        # Valid sort orders should work
        valid_params = ['created_at', 'next_test', 'next_ref_test']
        valid_params.each do |param|
          get :manage_verses, params: { sort_order: param }
          expect(response).to be_successful
        end
        
        # Invalid sort orders should fall back to default
        get :manage_verses, params: { sort_order: 'invalid_column' }
        expect(response).to be_successful
      end
    end
  end

  describe UtilsController, type: :controller do
    before(:each) do
      @user = FactoryBot.create(:user, admin: true)
      @user.confirm
      sign_in @user
    end
    
    describe "GET 'show_users'" do
      it "prevents SQL injection in sort_order parameter" do
        malicious_params = [
          "created_at; DELETE FROM users; --",
          "created_at) OR 1=1--",
          "created_at UNION SELECT password FROM users--"
        ]
        
        malicious_params.each do |param|
          expect {
            get :show_users, params: { sort_order: param }
          }.not_to raise_error
          
          expect(response).to be_successful
          expect(User.count).to be > 0
        end
      end
    end
  end
end