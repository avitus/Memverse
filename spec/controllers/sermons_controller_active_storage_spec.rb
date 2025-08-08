require 'spec_helper'

RSpec.describe SermonsController, type: :controller do
  let(:user) { FactoryBot.create(:user, admin: true) }
  let(:sermon) { FactoryBot.create(:sermon, user: user) }
  let(:test_file) { fixture_file_upload('test_audio.mp3', 'audio/mpeg') }
  
  before do
    user.confirm  # Confirm the user for Devise
    sign_in user
  end
  
  describe 'POST #create' do
    context 'with Active Storage attachment' do
      it 'creates a sermon with mp3_attachment' do
        expect {
          post :create, params: {
            sermon: {
              title: 'New Sermon',
              summary: 'Test summary',
              church_id: 'Test Church',
              pastor_id: 'Test Pastor',
              uberverse_id: 'John 3:16',
              mp3_attachment: test_file
            }
          }
        }.to change(Sermon, :count).by(1)
        
        new_sermon = Sermon.last
        expect(new_sermon.mp3_attachment).to be_attached
        expect(new_sermon.mp3_attachment.filename.to_s).to eq('test_audio.mp3')
      end
    end
  end
  
  describe 'PATCH #update' do
    it 'updates sermon with Active Storage attachment' do
      patch :update, params: {
        id: sermon.id,
        sermon: {
          mp3_attachment: test_file
        }
      }
      
      sermon.reload
      expect(sermon.mp3_attachment).to be_attached
      expect(sermon.mp3_attachment.filename.to_s).to eq('test_audio.mp3')
    end
  end
  
  describe 'GET #show' do
    context 'with Active Storage attachment' do
      before do
        sermon.mp3_attachment.attach(test_file)
      end
      
      it 'displays the sermon with attachment' do
        get :show, params: { id: sermon.id }
        expect(response).to be_successful
        expect(assigns(:sermon).mp3_attachment).to be_attached
      end
    end
    
    context 'without attachment' do
      it 'displays the sermon without attachment' do
        get :show, params: { id: sermon.id }
        expect(response).to be_successful
        expect(assigns(:sermon).mp3_attachment).not_to be_attached
      end
    end
  end
end