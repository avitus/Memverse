pdf.font "Helvetica" 

pdf.text "Memory Verses",	:size => 25, :align => :center, :style => :bold
pdf.text "www.memverse.com",	:size => 15, :align => :center

pdf.move_down(30)

for mv in @mv_list
		 
	pdf.text mv.verse.text, :size => 12, :align => :left, :spacing => 20
	pdf.text "#{mv.verse.ref} (#{mv.verse.translation})", :size =>  8, :align => :right, :spacing => 20
	pdf.horizontal_rule()
	pdf.stroke
	pdf.move_down(20)
	
end
