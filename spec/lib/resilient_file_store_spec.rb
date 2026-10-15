require 'rails_helper'
require 'tmpdir'
require_relative '../../lib/resilient_file_store'

RSpec.describe ResilientFileStore do
  let(:cache_dir) { Dir.mktmpdir('resilient_file_store') }
  let(:store) { described_class.new(cache_dir) }
  let(:plain_store) { ActiveSupport::Cache::FileStore.new(cache_dir) }
  let(:key) { 'onebox-views:https://example.com/post' }

  after { FileUtils.rm_rf(cache_dir) }

  # On-disk path FileStore uses for +key+.
  def entry_path(cache_store)
    cache_store.send(:normalize_key, key, {})
  end

  # Another thread's delete_entry rmdir's the bucket directory right after this
  # thread's ensure_cache_path saw it exist (MEMVERSE-9K).
  def vanish_bucket_after_ensure_cache_path(cache_store, times:)
    calls = 0
    allow(cache_store).to receive(:ensure_cache_path).and_wrap_original do |original, dir|
      original.call(dir)
      calls += 1
      FileUtils.rm_rf(dir) if calls <= times
    end
  end

  # Another thread deletes the file first, then rewrites it before FileStore's
  # rescue re-checks File.exist? (MEMVERSE-9R).
  def lose_delete_race(cache_store)
    allow(File).to receive(:delete).and_call_original
    allow(File).to receive(:delete).with(entry_path(cache_store)).and_raise(Errno::ENOENT)
  end

  it 'is a FileStore' do
    expect(store).to be_a(ActiveSupport::Cache::FileStore)
  end

  it 'round-trips write, read, fetch and delete as a normal FileStore' do
    expect(store.write(key, 'value')).to be(true)
    expect(store.read(key)).to eq('value')
    expect(store.fetch(key) { 'other' }).to eq('value')
    expect(store.delete(key)).to be(true)
    expect(store.read(key)).to be_nil
    expect(store.fetch(key) { 'computed' }).to eq('computed')
    expect(store.read(key)).to eq('computed')
  end

  describe '#write when the bucket directory vanishes mid-write' do
    it 'raises Errno::ENOENT on a plain FileStore' do
      vanish_bucket_after_ensure_cache_path(plain_store, times: 1)

      expect { plain_store.write(key, 'value') }.to raise_error(Errno::ENOENT)
    end

    it 'retries once and stores the value' do
      vanish_bucket_after_ensure_cache_path(store, times: 1)

      expect(store.write(key, 'value')).to be(true)
      expect(store.read(key)).to eq('value')
    end

    it 'returns false and logs a warning if the retry fails too' do
      log = StringIO.new
      allow(store).to receive(:logger).and_return(Logger.new(log))
      vanish_bucket_after_ensure_cache_path(store, times: 2)

      result = nil
      expect { result = store.write(key, 'value') }.not_to raise_error
      expect(result).to be(false)
      expect(log.string).to match(/WARN.*No such file or directory/)
      expect(store.read(key)).to be_nil
    end
  end

  describe '#delete when another thread wins the race' do
    it 'raises Errno::ENOENT on a plain FileStore' do
      plain_store.write(key, 'value')
      lose_delete_race(plain_store)

      expect { plain_store.delete(key) }.to raise_error(Errno::ENOENT)
    end

    it 'returns false without raising' do
      store.write(key, 'value')
      lose_delete_race(store)

      result = nil
      expect { result = store.delete(key) }.not_to raise_error
      expect(result).to be(false)
    end
  end

  describe '#fetch of an expired entry when the delete race is lost' do
    it 'raises Errno::ENOENT on a plain FileStore' do
      plain_store.write(key, 'stale', expires_in: 1.minute)

      travel(2.minutes) do
        lose_delete_race(plain_store)

        expect { plain_store.fetch(key, expires_in: 1.week) { 'fresh' } }.to raise_error(Errno::ENOENT)
      end
    end

    it 'treats the entry as a miss and returns the fresh value' do
      store.write(key, 'stale', expires_in: 1.minute)

      travel(2.minutes) do
        lose_delete_race(store)

        expect(store.fetch(key, expires_in: 1.week) { 'fresh' }).to eq('fresh')
        expect(store.read(key)).to eq('fresh')
      end
    end
  end
end
