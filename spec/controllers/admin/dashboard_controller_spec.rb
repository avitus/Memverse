require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, admin: true) }
  let(:regular_user) { FactoryBot.create(:user, admin: false) }
  
  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'redirects to root path with error message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('You must be an admin to access this page')
      end
    end
    
    context 'when regular user is logged in' do
      before { sign_in regular_user }
      
      it 'redirects to root path with error message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('You must be an admin to access this page')
      end
    end
    
    context 'when admin user is logged in' do
      before { sign_in admin_user }
      
      it 'renders the index template' do
        get :index
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end
      
      it 'returns 200 status code' do
        get :index
        expect(response).to have_http_status(200)
      end
    end
  end
end