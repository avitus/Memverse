class UpdateSubsections

  include Sidekiq::Worker
  include IceCube

  sidekiq_options :retry => false

  def perform

    puts "Starting calculation of subsection probabilities"
    BIBLEBOOKS[:en].values.each { |book|

      bi = BIBLEBOOKS[:en].values.index(book) + 1

      final_chapter = FinalVerse.where(book: book).order("chapter DESC").first.chapter

      (1..final_chapter).each { |chapter|

        subsection_end = Array.new

        final_verse   = FinalVerse.where(book: book, chapter: chapter).first.last_verse
        passage_count = Passage.where("length > 2 AND book = ? AND chapter = ?", book, chapter).count

        if passage_count > 0

          # Create array with number of times this verse is the last verse in a passage
          # We start at 2 because the first verse is obviously a subsection start
          first_verse_count = (2..final_verse).map { |vs|
            Passage.where("length > 2 AND book = ? AND chapter = ? AND first_verse = ?", book, chapter, vs).count
          }

          # Create array with number of times this verse is the last verse in a passage
          # We skip the last verse because it is obviously a subsection end for our purposes
          last_verse_count = (1..final_verse-1).map { |vs|
            Passage.where("length > 2 AND book = ? AND chapter = ? AND last_verse = ?", book, chapter, vs).count
          }

          # Add the two arrays to give an idea of the probability that this is usually an end verse
          # Idea: if subsequent verse is a first verse or this is an end verse then this is a good dividing point
          end_prob = first_verse_count.zip(last_verse_count).map {|x| (x.sum / passage_count.to_f * 100).to_i }

          # Pad probability array
          padded_end_prob = [0,0,0] + end_prob + [0,0,0]

          # Extract peaks as most likely passage breaks
          for i in 0..end_prob.length-1
            subsection_end[i] = -padded_end_prob[i  ]/6 \
                                -padded_end_prob[i+1]/4 \
                                -padded_end_prob[i+2]/2 \
                                +padded_end_prob[i+3]   \
                                -padded_end_prob[i+4]/2 \
                                -padded_end_prob[i+5]/4 \
                                -padded_end_prob[i+6]/6
          end

          # Remove negative values
          subsection_end.map! { |p| [p,0].max }
          subsection_end.push(100)    # Add final verse

          # Show output
          puts "#{book} #{chapter} : #{subsection_end}"

          # Save to DB
          subsection_end.each_with_index { |p, vs|
            Uberverse.where(book: book, chapter: chapter, versenum: vs+1).first.update_attribute(:subsection_end, p)
          }

        end

      }

    }

    puts "=== Finished calculating subsection probabilities at #{Time.now} ==="


  end

end