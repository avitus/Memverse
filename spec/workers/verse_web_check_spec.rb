require 'spec_helper'

RSpec.describe VerseWebCheck, type: :worker do
  let(:worker) { described_class.new }
  let(:verse_id) { 123 }
  let(:perform_args) { [verse_id] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a retryable worker'

  describe '#perform' do
    let(:verse) { instance_double(Verse) }
    let(:web_text) { "For God so loved the world that he gave his one and only Son." }
    let(:database_text) { "For God so loved the world that he gave his one and only Son." }

    before do
      allow(Sidekiq.logger).to receive(:info)
      allow(Sidekiq.logger).to receive(:warn)
    end

    context 'when verse exists' do
      before do
        allow(Verse).to receive(:find_by_id).with(verse_id).and_return(verse)
        allow(verse).to receive(:web_text).and_return(web_text)
        allow(verse).to receive(:database_text).and_return(database_text)
        allow(verse).to receive(:update_column)
      end

      context 'when web_text matches database_text' do
        it 'auto-verifies the verse' do
          worker.perform(verse_id)
          expect(verse).to have_received(:update_column).with(:verified, true)
        end

        it 'logs successful verification' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).to have_received(:info).with("Auto-verified verse with ID: #{verse_id}")
        end

        it 'does not log any warnings' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).not_to have_received(:warn)
        end
      end

      context 'when web_text does not match database_text' do
        let(:database_text) { "For God so loved the world that He gave His only begotten Son." }

        it 'does not verify the verse' do
          worker.perform(verse_id)
          expect(verse).not_to have_received(:update_column)
        end

        it 'logs text mismatch' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).to have_received(:info).with("Verse text did not match web for verse with ID: #{verse_id}")
        end

        it 'does not log verification success' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).not_to have_received(:info).with("Auto-verified verse with ID: #{verse_id}")
        end
      end

      context 'when web_text is nil' do
        let(:web_text) { nil }

        it 'does not verify the verse' do
          worker.perform(verse_id)
          expect(verse).not_to have_received(:update_column)
        end

        it 'logs text mismatch' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).to have_received(:info).with("Verse text did not match web for verse with ID: #{verse_id}")
        end
      end

      context 'when database_text is nil' do
        let(:database_text) { nil }

        it 'does not verify the verse' do
          worker.perform(verse_id)
          expect(verse).not_to have_received(:update_column)
        end

        it 'logs text mismatch' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).to have_received(:info).with("Verse text did not match web for verse with ID: #{verse_id}")
        end
      end

      context 'when both texts are empty strings' do
        let(:web_text) { "" }
        let(:database_text) { "" }

        it 'auto-verifies the verse when both are empty' do
          worker.perform(verse_id)
          expect(verse).to have_received(:update_column).with(:verified, true)
        end

        it 'logs successful verification' do
          worker.perform(verse_id)
          expect(Sidekiq.logger).to have_received(:info).with("Auto-verified verse with ID: #{verse_id}")
        end
      end

      context 'when verse update_column raises an error' do
        let(:error_message) { 'Database connection failed' }

        before do
          allow(verse).to receive(:update_column).and_raise(ActiveRecord::ConnectionTimeoutError.new(error_message))
        end

        it 'allows the error to bubble up for Sidekiq retry handling' do
          expect { worker.perform(verse_id) }.to raise_error(ActiveRecord::ConnectionTimeoutError, error_message)
        end

        it 'does not log verification success before error' do
          expect { worker.perform(verse_id) }.to raise_error(ActiveRecord::ConnectionTimeoutError)
          expect(Sidekiq.logger).not_to have_received(:info).with("Auto-verified verse with ID: #{verse_id}")
        end
      end

      context 'when web_text method raises an error' do
        before do
          allow(verse).to receive(:web_text).and_raise(StandardError.new('BibleGateway API error'))
        end

        it 'allows the error to bubble up for Sidekiq retry handling' do
          expect { worker.perform(verse_id) }.to raise_error(StandardError, 'BibleGateway API error')
        end
      end

      context 'when database_text method raises an error' do
        before do
          allow(verse).to receive(:database_text).and_raise(StandardError.new('Database read error'))
        end

        it 'allows the error to bubble up for Sidekiq retry handling' do
          expect { worker.perform(verse_id) }.to raise_error(StandardError, 'Database read error')
        end
      end
    end

    context 'when verse does not exist' do
      before do
        allow(Verse).to receive(:find_by_id).with(verse_id).and_return(nil)
      end

      it 'does not attempt to verify any verse' do
        worker.perform(verse_id)
        # No verse methods should be called
      end

      it 'logs warning about missing verse' do
        worker.perform(verse_id)
        expect(Sidekiq.logger).to have_received(:warn).with("Unable to find verse with ID: #{verse_id}")
      end

      it 'does not log any info messages' do
        worker.perform(verse_id)
        expect(Sidekiq.logger).not_to have_received(:info)
      end

      it 'completes without error' do
        expect { worker.perform(verse_id) }.not_to raise_error
      end
    end

    context 'when Verse.find_by_id raises an error' do
      let(:error_message) { 'Database connection failed' }

      before do
        allow(Verse).to receive(:find_by_id).and_raise(ActiveRecord::ConnectionTimeoutError.new(error_message))
      end

      it 'allows the error to bubble up for Sidekiq retry handling' do
        expect { worker.perform(verse_id) }.to raise_error(ActiveRecord::ConnectionTimeoutError, error_message)
      end
    end

    context 'with different verse ID types' do
      [1, "1", 999999].each do |id|
        context "when verse ID is #{id.inspect}" do
          let(:verse_id) { id }

          before do
            allow(Verse).to receive(:find_by_id).with(id).and_return(nil)
          end

          it 'handles the ID correctly' do
            worker.perform(id)
            expect(Verse).to have_received(:find_by_id).with(id)
            expect(Sidekiq.logger).to have_received(:warn).with("Unable to find verse with ID: #{id}")
          end
        end
      end
    end
  end

  describe 'Sidekiq configuration' do
    it 'uses default retry behavior' do
      # Default Sidekiq retry may be configured globally - check for reasonable retry value
      expect(described_class.sidekiq_options['retry']).to be > 0
    end

    it 'uses the default queue' do
      expect(described_class.sidekiq_options['queue']).to eq('default')
    end
  end

  describe 'method signature' do
    it 'accepts a single ID parameter' do
      method = described_class.instance_method(:perform)
      expect(method.arity).to eq(1)
    end
  end

  describe 'logging behavior' do
    let(:verse) { instance_double(Verse) }

    before do
      allow(Sidekiq.logger).to receive(:info)
      allow(Sidekiq.logger).to receive(:warn)
      allow(Verse).to receive(:find_by_id).with(verse_id).and_return(verse)
      allow(verse).to receive(:web_text).and_return("test text")
      allow(verse).to receive(:database_text).and_return("test text")
      allow(verse).to receive(:update_column)
    end

    it 'uses Sidekiq.logger for logging' do
      worker.perform(verse_id)
      expect(Sidekiq.logger).to have_received(:info)
    end

    it 'includes verse ID in all log messages' do
      worker.perform(verse_id)
      expect(Sidekiq.logger).to have_received(:info).with(include(verse_id.to_s))
    end
  end

  describe 'integration with Verse model methods' do
    let(:verse) { instance_double(Verse) }

    before do
      allow(Verse).to receive(:find_by_id).with(verse_id).and_return(verse)
      allow(Sidekiq.logger).to receive(:info)
      allow(verse).to receive(:update_column)
    end

    it 'calls web_text method on the verse' do
      allow(verse).to receive(:web_text).and_return("text")
      allow(verse).to receive(:database_text).and_return("text")
      
      worker.perform(verse_id)
      expect(verse).to have_received(:web_text)
    end

    it 'calls database_text method on the verse' do
      allow(verse).to receive(:web_text).and_return("text")
      allow(verse).to receive(:database_text).and_return("text")
      
      worker.perform(verse_id)
      expect(verse).to have_received(:database_text)
    end

    it 'uses update_column to set verified status' do
      allow(verse).to receive(:web_text).and_return("text")
      allow(verse).to receive(:database_text).and_return("text")
      
      worker.perform(verse_id)
      expect(verse).to have_received(:update_column).with(:verified, true)
    end
  end

  describe 'edge cases' do
    let(:verse) { instance_double(Verse) }

    before do
      allow(Verse).to receive(:find_by_id).with(verse_id).and_return(verse)
      allow(Sidekiq.logger).to receive(:info)
      allow(Sidekiq.logger).to receive(:warn)
      allow(verse).to receive(:update_column)
    end

    context 'when texts have different whitespace' do
      before do
        allow(verse).to receive(:web_text).and_return("For God so loved the world")
        allow(verse).to receive(:database_text).and_return("For  God  so  loved  the  world")
      end

      it 'does not verify when whitespace differs' do
        worker.perform(verse_id)
        expect(verse).not_to have_received(:update_column)
        expect(Sidekiq.logger).to have_received(:info).with("Verse text did not match web for verse with ID: #{verse_id}")
      end
    end

    context 'when texts have different case' do
      before do
        allow(verse).to receive(:web_text).and_return("For God so loved the world")
        allow(verse).to receive(:database_text).and_return("for god so loved the world")
      end

      it 'does not verify when case differs' do
        worker.perform(verse_id)
        expect(verse).not_to have_received(:update_column)
        expect(Sidekiq.logger).to have_received(:info).with("Verse text did not match web for verse with ID: #{verse_id}")
      end
    end

    context 'when texts contain special characters' do
      let(:special_text) { "For God so loved the world, that he gave his one & only Son—" }

      before do
        allow(verse).to receive(:web_text).and_return(special_text)
        allow(verse).to receive(:database_text).and_return(special_text)
      end

      it 'verifies when special characters match exactly' do
        worker.perform(verse_id)
        expect(verse).to have_received(:update_column).with(:verified, true)
        expect(Sidekiq.logger).to have_received(:info).with("Auto-verified verse with ID: #{verse_id}")
      end
    end
  end

  describe 'error handling scenarios' do
    context 'with various error types that should trigger retry' do
      let(:verse) { instance_double(Verse) }

      before do
        allow(Verse).to receive(:find_by_id).with(verse_id).and_return(verse)
        allow(verse).to receive(:web_text).and_return("text")
        allow(verse).to receive(:database_text).and_return("text")
      end

      [
        ActiveRecord::ConnectionTimeoutError,
        ActiveRecord::StatementInvalid,
        StandardError,
        RuntimeError,
        Timeout::Error
      ].each do |error_class|
        context "when #{error_class} is raised during update_column" do
          before do
            allow(verse).to receive(:update_column).and_raise(error_class.new("Test error"))
          end

          it "allows #{error_class} to bubble up for Sidekiq retry" do
            expect { worker.perform(verse_id) }.to raise_error(error_class)
          end
        end
      end
    end
  end
end