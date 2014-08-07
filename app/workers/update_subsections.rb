class KnowledgeQuiz

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false

  recurrence do
    weekly.day(:sunday).hour_of_day(9)    # Every Sunday at 9am
  end

  def perform

    # irb(main):012:0> (1..34).map { |v| Passage.where("length > 1 AND book = ? AND chapter = ? AND last_verse = ?", 'Matthew', 6, v).count }
    # => [0, 2, 3, 20, 1, 2, 4, 4, 0, 4, 4, 5, 158, 8, 137, 3, 2, 3, 0, 10, 141, 3, 7, 8, 5, 5, 7, 0, 4, 4, 1, 1, 17, 409]
    # irb(main):013:0> (1..34).map { |v| Passage.where("length > 1 AND book = ? AND chapter = ? AND first_verse = ?", 'Matthew', 6, v).count }
    # => [316, 1, 10, 0, 13, 6, 0, 1, 272, 5, 0, 0, 3, 15, 0, 3, 40, 2, 108, 14, 0, 6, 1, 19, 45, 3, 1, 3, 2, 2, 23, 5, 63, 0]



  end

end