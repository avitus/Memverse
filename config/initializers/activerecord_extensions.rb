module MemverseActiveRecordExtensions
  def every(n)
    all.select {|x| all.index(x) % n == 0}
  end
end

ActiveRecord::Base.extend MemverseActiveRecordExtensions