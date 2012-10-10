/******************************************************************************
 * Display compact list of verse references
 ******************************************************************************/
function displayMvSearchResultsFn( verses ) {
    resetScrollable();

    $(".mv-search-results-compact #actions a, .mv-search-results-compact div.scrollable, .mv-search-results-compact").show();
    
    // wrap single verse in array
    if( !($.isArray(verses)) ) {
        verses = [ verses ]; 
    }

    $.each (verses, function(i, vs) {
        
        // We need to group search results to enable scroll      
        if (i % 7 == 0) {
            // Start new group
            var $new_vs_group = $('<div/>').addClass('search-result-group');
            $('.items').append($new_vs_group);
        }

        // Show start of verse
        var shortText = jQuery.trim(vs.text).substring(0, 35).split(" ").slice(0, -1).join(" ") + "...";

        // Build HTML for each verse
        var $new_vs = $('<div/>').addClass('item')
            
            // verse reference
            .append( $('<div class="ref-and-details" />')
                .append($('<h4 class="ref"         />').text( vs.ref      ))
                .append($('<p  class="first-words" />').text( shortText   )) 
                .append($('<p  class="full-text"   />').text( vs.text     )) 
                .append($('<p  class="mnemonic"    />').text( vs.mnemonic )) 
                .append($('<p  class="mv-id"       />').text( vs.id       )) 
            )
            
            // add button
            .append('<div class="select-verse-button"><a href="#" class="compact-add-button"></a></div>');

        $('.search-result-group').filter(':last').append($new_vs);                                                              
    }); 

}

