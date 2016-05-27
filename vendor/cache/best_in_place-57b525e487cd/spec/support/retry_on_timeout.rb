def retry_on_timeout(n = 3, &block)
  block.call
rescue => e
  fail if n.zero?
  puts "Caught error: #{e.message}. #{n-1} more attempts."
  retry_on_timeout(n - 1, &block)
end