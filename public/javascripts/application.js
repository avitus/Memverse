// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function stageverse(skip, mv_current) {
	
	var mv = {};
	
	$.getJSON("/memverses/test_next_verse", { skip: false, mv: mv_current },
		function(data){
				
			mv.finished	= data.finished;
						
			if (!mv.finished)
			{					
				// data for the next verse ...
				mv.ref 		= data.ref;
				mv.id		= data.mv_id;	 
				mv.txt 		= data.next.verse.text;
				mv.versenum	= data.next.verse.versenum;
				
				// ... and its prior verse
				if(typeof(data.next_prior) !== 'undefined' && data.next_prior != null)
				{
					mv.priortxt	= data.next_prior.verse.text;
					mv.priornum	= data.next_prior.verse.versenum;				 	
				}
				else
				{
					mv.priortxt	= null;
					mv.priornum	= null;
				}
			}			
	}); // end of getJSON
	
	return mv;	
};
	