require "active_support/cache"

# FileStore that survives concurrent access to the same key. Thredded renders a
# page's posts in parallel threads, so a onebox link in two posts makes two
# threads fetch the same expired entry: one thread's delete can rmdir the bucket
# directory under the other's write (MEMVERSE-9K), or both can race on the same
# File.delete (MEMVERSE-9R). The cache is an optimisation, so neither may 500.
class ResilientFileStore < ActiveSupport::Cache::FileStore
  private

  # Retries once if the bucket directory vanished; gives up quietly after that.
  def write_serialized_entry(key, payload, **options)
    super
  rescue Errno::ENOENT
    begin
      super # ensure_cache_path recreates the bucket directory
    rescue Errno::ENOENT => e
      (logger || Rails.logger)&.warn("ResilientFileStore: cache write skipped after retry (#{e.message})")
      false
    end
  end

  # Another thread or process already handled this entry.
  def delete_entry(key, **options)
    super
  rescue Errno::ENOENT
    false
  end
end
