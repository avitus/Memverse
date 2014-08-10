pdf.font "Helvetica"

pdf.text @quiz.name, size: 20, align: :center, style: :bold
pdf.text "Multiple Choice", size: 16, align: :center

pdf.move_down(30)

for i in 1..@mcquestions.length
  pdf.text "#{i}. #{@mcquestions[i-1].mc_question}", size: 12, align: :left, spacing: 20

  pdf.move_down 8

  for option in ["a", "b", "c", "d"]
    pdf.text "(#{option.upcase}) #{@mcquestions[i-1].send("mc_option_"+option)}", size: 12, align: :left
  end

  pdf.move_down 10
  pdf.horizontal_rule
  pdf.stroke
  pdf.move_down 10
end

pdf.start_new_page

pdf.text "Answers", size: 18, align: :center, style: :bold

for i in 1..@mcquestions.length
  pdf.text "#{i}. #{@mcquestions[i-1].mc_answer}"
end
