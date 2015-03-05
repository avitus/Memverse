require_relative 'helper'

class TestWatcher < Sidetiq::TestCase
  def setup
    Sidetiq.config.lock.watcher.remove_lock = true
    Sidetiq.config.lock.watcher.notify = true

    @worker = Sidetiq::Lock::Watcher.new
  end

  def test_perform
    Sidetiq::Lock::Redis.new("foobar", 1000000).lock

    assert_equal 1, Sidetiq::Lock::Redis.all.length

    @worker.expects(:handle_exception).once

    @worker.perform

    assert_equal 0, Sidetiq::Lock::Redis.all.length
  end
end


