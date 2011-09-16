pdf.font "Helvetica" 

pdf.text "Memory Verse Prompts",	:size => 25, :align => :center, :style => :bold
pdf.text "www.memverse.com",		:size => 15, :align => :center

pdf.move_down(30)

for mv in @mv_list
		 
	pdf.text "#{mv.verse.ref} (#{mv.verse.translation})", :size =>  12, :align => :left, :spacing => 20
	pdf.text mv.verse.mnemonic, :size => 10, :align => :left, :spacing => 25
	pdf.horizontal_rule()
	pdf.stroke
	pdf.move_down(20)
	
end
