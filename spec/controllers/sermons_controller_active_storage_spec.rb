require 'spec_helper'

RSpec.describe SermonsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:sermon) { FactoryBot.create(:sermon, user: user) }
  let(:test_file) { fixture_file_upload('test_audio.mp3', 'audio/mpeg') }
  
  before do
    sign_in user
  end
  
  describe 'POST #create' do
    context 'with Active Storage attachment' do
      xit 'creates a sermon with mp3_attachment' do
        expect {
          post :create, params: {
            sermon: {
              title: 'New Sermon',
              summary: 'Test summary',
              mp3_attachment: test_file
            }
          }
        }.to change(Sermon, :count).by(1)
        
        sermon = Sermon.last
        expect(sermon.mp3_attachment).to be_attached
        expect(sermon.mp3_attachment.filename.to_s).to eq('test_audio.mp3')
      end
    end
    
    context 'with Paperclip attachment' do
      xit 'creates a sermon with mp3' do
        expect {
          post :create, params: {
            sermon: {
              title: 'New Sermon',
              summary: 'Test summary',
              mp3: test_file
            }
          }
        }.to change(Sermon, :count).by(1)
        
        sermon = Sermon.last
        expect(sermon.mp3_file_name).to eq('test_audio.mp3')
      end
    end
  end
  
  describe 'PATCH #update' do
    context 'updating to Active Storage' do
      before do
        # Start with a Paperclip attachment
        sermon.update(
          mp3_file_name: 'old_audio.mp3',
          mp3_content_type: 'audio/mpeg',
          mp3_file_size: 1024
        )
      end
      
      xit 'updates sermon with new Active Storage attachment' do
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
  end
  
  describe 'GET #show' do
    context 'with Active Storage attachment' do
      before do
        sermon.mp3_attachment.attach(test_file)
      end
      
      xit 'displays the sermon with attachment' do
        get :show, params: { id: sermon.id }
        expect(response).to be_successful
        expect(assigns(:sermon).mp3_attachment).to be_attached
      end
    end
    
    context 'with Paperclip attachment' do
      before do
        sermon.update(
          mp3_file_name: 'paperclip_audio.mp3',
          mp3_content_type: 'audio/mpeg'
        )
      end
      
      xit 'displays the sermon with Paperclip file' do
        get :show, params: { id: sermon.id }
        expect(response).to be_successful
        expect(assigns(:sermon).mp3_file_name).to eq('paperclip_audio.mp3')
      end
    end
  end
end