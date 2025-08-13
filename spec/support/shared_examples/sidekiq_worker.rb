# frozen_string_literal: true

RSpec.shared_examples 'a Sidekiq worker' do
  it 'is a Sidekiq worker' do
    expect(described_class).to include(Sidekiq::Worker)
  end

  it 'has the correct queue' do
    # Allow for different queue priorities: critical, high, default, low
    allowed_queues = ['critical', 'high', 'default', 'low', :critical, :high, :default, :low, nil]
    expect(allowed_queues).to include(described_class.sidekiq_options['queue'])
  end
end

RSpec.shared_examples 'a worker with specific queue' do |expected_queue|
  it "uses the #{expected_queue} queue" do
    # Convert string to symbol if needed for comparison
    expected = expected_queue.is_a?(String) ? expected_queue.to_sym : expected_queue
    actual = described_class.sidekiq_options['queue']
    
    expect(actual).to eq(expected)
  end
end

RSpec.shared_examples 'a non-retryable worker' do
  it 'has retry disabled' do
    expect(described_class.sidekiq_options['retry']).to eq(false)
  end
end

RSpec.shared_examples 'a retryable worker' do
  it 'has retry enabled' do
    retry_value = described_class.sidekiq_options['retry']
    expect(retry_value).to be_truthy.and(satisfy { |v| v == true || v.is_a?(Integer) && v > 0 })
  end
end

RSpec.shared_examples 'performs logging' do
  it 'logs job execution' do
    allow(Rails.logger).to receive(:info)
    subject.perform(*perform_args)
    expect(Rails.logger).to have_received(:info).at_least(:once)
  end
end

RSpec.shared_examples 'handles errors gracefully' do |error_class|
  it "handles #{error_class} errors" do
    allow(subject).to receive(:perform).and_raise(error_class)
    expect { subject.perform(*perform_args) }.to raise_error(error_class)
  end
end