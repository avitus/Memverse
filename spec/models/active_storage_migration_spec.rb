require 'spec_helper'

RSpec.describe 'Active Storage', type: :model do
  describe 'Sermon model' do
    let(:sermon) { FactoryBot.create(:sermon) }
    
    context 'with Active Storage attachment' do
      before do
        sermon.mp3_attachment.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_audio.mp3')),
          filename: 'test_audio.mp3',
          content_type: 'audio/mpeg'
        )
      end
      
      it 'has attached mp3_attachment' do
        expect(sermon.mp3_attachment).to be_attached
      end
      
      it 'returns correct mp3_url' do
        expect(sermon.mp3_url).to include('rails/active_storage/blobs')
      end
      
      it 'returns Active Storage attachment' do
        expect(sermon.mp3).to eq(sermon.mp3_attachment)
      end
    end
    
    context 'without any attachment' do
      it 'returns nil for mp3_url' do
        expect(sermon.mp3_url).to be_nil
      end
      
      it 'returns nil for mp3' do
        expect(sermon.mp3).to be_nil
      end
    end
  end
  
  describe 'CKEditor::Picture model' do
    let(:picture) { FactoryBot.create(:ckeditor_picture) }
    
    context 'with Active Storage attachment' do
      
      it 'has attached data_attachment' do
        expect(picture.data_attachment).to be_attached
      end
      
      it 'returns correct url for original' do
        expect(picture.url).to include('rails/active_storage/blobs')
      end
      
      it 'returns correct url_content with variant' do
        expect(picture.url_content).to include('rails/active_storage/representations')
      end
      
      it 'returns correct url_thumb with variant' do
        expect(picture.url_thumb).to include('rails/active_storage/representations')
      end
      
      it 'validates attachment size' do
        large_file = StringIO.new('x' * 3.megabytes)
        picture.data_attachment.attach(
          io: large_file,
          filename: 'large.jpg',
          content_type: 'image/jpeg'
        )
        picture.valid?
        expect(picture.errors[:data_attachment]).to include('must be less than 2MB')
      end
    end
    
    context 'without attachment' do
      let(:picture_without_attachment) { FactoryBot.build(:ckeditor_picture) }
      
      before do
        # Clear any attached files from the factory
        picture_without_attachment.data_attachment.purge if picture_without_attachment.data_attachment.attached?
      end
      
      it 'validates attachment presence' do
        picture_without_attachment.valid?
        expect(picture_without_attachment.errors[:data_attachment]).to include("can't be blank")
      end
    end
  end
  
  describe 'CKEditor::AttachmentFile model' do
    let(:attachment) { FactoryBot.create(:ckeditor_attachment_file) }
    
    context 'with Active Storage attachment' do
      
      it 'has attached data_attachment' do
        expect(attachment.data_attachment).to be_attached
      end
      
      it 'returns correct filename' do
        expect(attachment.filename).to eq('test_document.pdf')
      end
      
      it 'returns correct url' do
        expect(attachment.url).to include('rails/active_storage/blobs')
      end
      
      it 'validates attachment size' do
        large_file = StringIO.new('x' * 101.megabytes)
        attachment.data_attachment.attach(
          io: large_file,
          filename: 'huge.pdf',
          content_type: 'application/pdf'
        )
        attachment.valid?
        expect(attachment.errors[:data_attachment]).to include('must be less than 100MB')
      end
    end
    
    context 'without attachment' do
      let(:attachment_without_file) { FactoryBot.build(:ckeditor_attachment_file) }
      
      before do
        # Clear any attached files from the factory
        attachment_without_file.data_attachment.purge if attachment_without_file.data_attachment.attached?
      end
      
      it 'returns nil for filename' do
        expect(attachment_without_file.filename).to be_nil
      end
      
      it 'returns nil for url' do
        expect(attachment_without_file.url).to be_nil
      end
      
      it 'validates attachment presence' do
        attachment_without_file.valid?
        expect(attachment_without_file.errors[:data_attachment]).to include("can't be blank")
      end
    end
  end
end